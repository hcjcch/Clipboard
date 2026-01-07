//
//  ClipboardHistoryViewModel.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import Foundation

@MainActor
class ClipboardHistoryViewModel: ObservableObject {
    static let shared = ClipboardHistoryViewModel()

    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var filteredItems: [ClipboardItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 键盘导航状态
    @Published var selectedItemIndex: Int? = nil
    @Published var isKeyboardNavigating: Bool = false

    // 动画触发状态
    @Published var animatingItemId: String? = nil

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotifications()
        setupSearchDebounce()
        loadItems()
    }

    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .clipboardDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadItems()
                }
            }
            .store(in: &cancellables)
    }

    /// 设置搜索防抖
    private func setupSearchDebounce() {
        // 监听 searchText 变化，延迟 150ms 后执行搜索
        $searchText
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.performSearch()
                // 搜索时重置选中状态
                self?.resetSelection()
            }
            .store(in: &cancellables)
    }

    /// 执行搜索（更新 filteredItems）
    private func performSearch() {
        if searchText.isEmpty {
            filteredItems = items
            return
        }

        // 使用模糊匹配，并按匹配度排序
        let matchedItems = items.compactMap { item -> (ClipboardItem, Double)? in
            let result = FuzzyMatcher.match(item.content, keyword: searchText)
            return result.matched ? (item, result.score) : nil
        }

        // 按得分降序排序
        filteredItems = matchedItems
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    /// 加载剪贴板历史
    func loadItems() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedItems = try await DatabaseService.shared.fetchAll()
                self.items = fetchedItems
                // 如果搜索框为空，更新 filteredItems
                if searchText.isEmpty {
                    self.filteredItems = fetchedItems
                }
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("加载剪贴板历史失败: \(error.localizedDescription)")
            }
        }
    }

    /// 搜索剪贴板项
    func search() {
        guard !searchText.isEmpty else {
            loadItems()
            return
        }

        isLoading = true

        Task {
            do {
                let results = try await DatabaseService.shared.search(keyword: searchText)
                self.items = results
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    /// 选择项并复制到剪贴板
    func selectItem(_ item: ClipboardItem) {
        Task {
            await ClipboardMonitorService.shared.copyToClipboard(item)
        }
    }

    /// 删除项
    func deleteItem(_ item: ClipboardItem) async {
        do {
            try await DatabaseService.shared.delete(id: item.id)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 清空所有
    func clearAll() async {
        isLoading = true
        errorMessage = nil

        do {
            try await DatabaseService.shared.clearAll()
            items = []
            filteredItems = []
        } catch {
            errorMessage = "清空失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 键盘导航

    /// 向上移动选中项
    func moveSelectionUp() {
        guard !filteredItems.isEmpty else { return }

        if let currentIndex = selectedItemIndex {
            // 向上移动，最小为 0
            selectedItemIndex = max(0, currentIndex - 1)
        } else {
            // 首次导航，选中最后一个（符合 macOS 习惯）
            selectedItemIndex = filteredItems.count - 1
        }
        isKeyboardNavigating = true
    }

    /// 向下移动选中项
    func moveSelectionDown() {
        guard !filteredItems.isEmpty else { return }

        if let currentIndex = selectedItemIndex {
            // 向下移动，最大为 count - 1
            selectedItemIndex = min(filteredItems.count - 1, currentIndex + 1)
        } else {
            // 首次导航，选中第一个
            selectedItemIndex = 0
        }
        isKeyboardNavigating = true
    }

    /// 确认选择（复制并关闭窗口）
    func confirmSelection() {
        guard let index = selectedItemIndex,
              index < filteredItems.count else { return }

        let selectedItem = filteredItems[index]
        selectItem(selectedItem)

        // 触发动画
        animatingItemId = selectedItem.id

        // 等待动画完成后隐藏窗口
        Task {
            // 等待动画完成通知（最多等待 2 秒）
            await waitForAnimationComplete()
            ClipboardWindowManager.shared.hideWindow()
        }
    }

    /// 等待动画完成
    private func waitForAnimationComplete() async {
        await withCheckedContinuation { continuation in
            var resumed = false
            var observer: NSObjectProtocol?

            observer = NotificationCenter.default.addObserver(
                forName: .copyAnimationDidComplete,
                object: nil,
                queue: .main
            ) { _ in
                if !resumed {
                    resumed = true
                    continuation.resume()
                    if let obs = observer {
                        NotificationCenter.default.removeObserver(obs)
                    }
                }
            }

            // 添加超时保护（2 秒）
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if !resumed {
                    resumed = true
                    continuation.resume()
                    if let obs = observer {
                        NotificationCenter.default.removeObserver(obs)
                    }
                }
            }
        }
    }

    /// 重置选中状态
    func resetSelection() {
        selectedItemIndex = nil
        isKeyboardNavigating = false
    }
}

import Combine

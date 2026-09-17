//
//  ClipboardHistoryViewModel.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Foundation

@MainActor
class ClipboardHistoryViewModel: ObservableObject {
    static let shared = ClipboardHistoryViewModel()

    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var filteredItems: [ClipboardItem] = []
    @Published var isLoading: Bool = false
    @Published private(set) var isLoadingNextPage: Bool = false
    @Published var errorMessage: String?

    // 键盘导航状态
    @Published var selectedItemIndex: Int? = nil
    @Published var isKeyboardNavigating: Bool = false

    // 动画触发状态
    @Published var animatingItemId: String? = nil

    // 预览面板状态
    @Published var previewPanelState: PreviewPanelState = .hidden
    let previewPanelViewModel = PreviewPanelViewModel()
    private let hoverState = HoverState()

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var pageLoadTask: Task<Void, Never>?
    private var nextPageOffset = 0
    private var hasMorePages = true
    private var loadGeneration = 0
    private let pageSize = 100

    private init() {
        setupNotifications()
        setupSearchDebounce()
        setupHoverState()
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
                self?.performSearch(for: searchText)
                // 搜索时重置选中状态
                self?.resetSelection()
            }
            .store(in: &cancellables)
    }

    /// 执行搜索（更新 filteredItems）
    private func performSearch(for query: String) {
        searchTask?.cancel()

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            filteredItems = items
            return
        }

        errorMessage = nil

        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let results = try await DatabaseService.shared.fuzzySearch(keyword: normalizedQuery)
                try Task.checkCancellation()

                guard searchText == query else { return }
                filteredItems = results
            } catch is CancellationError {
                // 新搜索会取消旧任务，避免过期结果覆盖当前输入。
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 加载剪贴板历史的第一页
    func loadItems() {
        pageLoadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration

        nextPageOffset = 0
        hasMorePages = true
        isLoadingNextPage = false
        isLoading = items.isEmpty
        errorMessage = nil

        pageLoadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await DatabaseService.shared.fetchPage(offset: 0, limit: pageSize)
                try Task.checkCancellation()
                guard generation == loadGeneration else { return }

                items = page.items
                nextPageOffset = page.items.count
                hasMorePages = page.hasMore
                isLoading = false

                if searchText.isEmpty {
                    filteredItems = page.items
                } else {
                    performSearch(for: searchText)
                }
            } catch is CancellationError {
                // 更新触发的新加载会替换旧任务。
            } catch {
                guard generation == loadGeneration else { return }
                errorMessage = error.localizedDescription
                isLoading = false
                print("加载剪贴板历史失败: \(error.localizedDescription)")
            }
        }
    }

    /// 当最后一行进入可视区域时加载下一页
    func loadNextPageIfNeeded(currentItem: ClipboardItem) {
        guard searchText.isEmpty,
              hasMorePages,
              !isLoadingNextPage,
              currentItem.id == items.last?.id else {
            return
        }

        let generation = loadGeneration
        let offset = nextPageOffset
        isLoadingNextPage = true

        Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await DatabaseService.shared.fetchPage(offset: offset, limit: pageSize)
                try Task.checkCancellation()
                guard generation == loadGeneration, searchText.isEmpty else { return }

                let existingIDs = Set(items.map(\.id))
                let newItems = page.items.filter { !existingIDs.contains($0.id) }
                items.append(contentsOf: newItems)
                filteredItems = items
                nextPageOffset = offset + page.items.count
                hasMorePages = page.hasMore
                isLoadingNextPage = false
            } catch is CancellationError {
                isLoadingNextPage = false
            } catch {
                guard generation == loadGeneration else { return }
                errorMessage = error.localizedDescription
                isLoadingNextPage = false
            }
        }
    }

    /// 搜索剪贴板项
    func search() {
        guard !searchText.isEmpty else {
            loadItems()
            return
        }
        performSearch(for: searchText)
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
            NotificationCenter.default.post(
                name: .clipboardItemDidDelete,
                object: nil,
                userInfo: ["itemId": item.id]
            )
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 切换置顶状态
    func togglePinned(_ item: ClipboardItem) {
        Task {
            do {
                try await DatabaseService.shared.updatePinned(id: item.id, isPinned: !item.isPinned)
                loadItems()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 清空所有
    func clearAll() async {
        searchTask?.cancel()
        pageLoadTask?.cancel()
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

    /// 当前键盘选中项的稳定标识
    var selectedItemID: String? {
        guard let selectedItemIndex,
              filteredItems.indices.contains(selectedItemIndex) else {
            return nil
        }
        return filteredItems[selectedItemIndex].id
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

    // MARK: - Preview Panel

    /// 当前悬停的剪贴板项
    var hoveredItem: ClipboardItem? {
        hoverState.currentItem
    }

    /// 是否应该显示预览面板
    var shouldShowPreview: Bool {
        if case .showing = previewPanelState {
            return true
        }
        return false
    }

    /// 处理列表项悬停事件
    /// - Parameter item: 悬停的剪贴板项
    func onItemHovered(_ item: ClipboardItem) {
        // 键盘导航时禁用鼠标悬停预览
        guard !isKeyboardNavigating else { return }

        hoverState.startHover(for: item, delay: 0.2)
    }

    /// 处理列表项离开事件
    func onItemExited() {
        hoverState.cancelHover()
        previewPanelViewModel.hidePreview()
        PreviewPanelWindowManager.shared.hidePreview()
        previewPanelState = .hidden
    }

    /// 处理列表项焦点事件（键盘导航）
    /// - Parameter item: 获得焦点的剪贴板项
    func onItemFocused(_ item: ClipboardItem) {
        // 键盘导航时立即显示预览（无延迟）
        previewPanelViewModel.showPreview(for: item)
        previewPanelState = .showing(item)

        // 显示浮动预览面板
        if let mainWindow = ClipboardWindowManager.shared.mainWindow {
            PreviewPanelWindowManager.shared.showPreview(for: item, mainWindow: mainWindow)
        }
    }

    /// 设置悬停状态
    private func setupHoverState() {
        hoverState.onHoverReady = { [weak self] item in
            guard let self = self, let item = item else { return }
            self.previewPanelViewModel.showPreview(for: item)
            self.previewPanelState = .showing(item)

            // 显示浮动预览面板
            if let mainWindow = ClipboardWindowManager.shared.mainWindow {
                PreviewPanelWindowManager.shared.showPreview(for: item, mainWindow: mainWindow)
            }
        }
    }
}

import Combine

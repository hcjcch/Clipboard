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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotifications()
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

    /// 加载剪贴板历史
    func loadItems() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedItems = try await DatabaseService.shared.fetchAll()
                self.items = fetchedItems
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
        do {
            try await DatabaseService.shared.clearAll()
            items = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 过滤后的项
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
}

import Combine

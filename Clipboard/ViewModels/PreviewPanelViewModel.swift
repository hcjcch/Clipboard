//
//  PreviewPanelViewModel.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import Combine
import Foundation

/// 预览面板视图模型
///
/// 职责：
/// - 管理预览面板的显示状态
/// - 加载预览内容（文本、图片、文件）
/// - 响应剪贴板项的变化（更新/删除）
/// - 提供去抖动逻辑以优化性能
@MainActor
class PreviewPanelViewModel: ObservableObject {
    // MARK: - Published State

    /// 预览面板的当前状态
    @Published var panelState: PreviewPanelState = .hidden

    // MARK: - Dependencies

    private let imageStorageService: ImageStorageService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// 初始化视图模型
    /// - Parameter imageStorageService: 图片存储服务，默认使用单例
    init(imageStorageService: ImageStorageService = .shared) {
        self.imageStorageService = imageStorageService
        setupContentObservers()
    }

    deinit {
        // Note: cancellables cleanup is handled automatically by ARC
    }

    // MARK: - Public Methods

    /// 显示指定剪贴板项的预览
    /// - Parameter item: 要预览的剪贴板项
    func showPreview(for item: ClipboardItem) {
        panelState = .loading
        loadPreviewContent(for: item)
    }

    /// 隐藏预览面板
    func hidePreview() {
        panelState = .hidden
    }

    /// 刷新当前预览内容（响应剪贴板项更新）
    func refreshPreviewContent() {
        guard case .showing(let item) = panelState else { return }
        panelState = .loading
        loadPreviewContent(for: item)
    }

    // MARK: - Private Methods - Content Loading

    /// 加载预览内容
    /// - Parameter item: 剪贴板项
    private func loadPreviewContent(for item: ClipboardItem) {
        switch item.type {
        case .text:
            loadTextContent(item)
        case .image:
            loadImageContent(item)
        case .file:
            loadFileContent(item)
        }
    }

    /// 加载文本内容
    /// - Parameter item: 剪贴板项
    private func loadTextContent(_ item: ClipboardItem) {
        // 文本内容立即可用（已在 ClipboardItem.content 中）
        panelState = .showing(item)
    }

    /// 加载图片内容
    /// - Parameter item: 剪贴板项
    private func loadImageContent(_ item: ClipboardItem) {
        // 优先使用缩略图
        if let thumbnail = item.thumbnailData {
            panelState = .showing(item)
            return
        }

        // 缩略图不存在时，加载原图
        guard let imagePath = item.imagePath else {
            panelState = .error("无法预览此图片")
            return
        }

        // 异步加载原图
        Task {
            do {
                let data = await imageStorageService.loadImage(imageId: imagePath)
                if data != nil {
                    // 原图加载成功，更新状态
                    self.panelState = .showing(item)
                } else {
                    self.panelState = .error("加载图片失败")
                }
            }
        }
    }

    /// 加载文件内容
    /// - Parameter item: 剪贴板项
    private func loadFileContent(_ item: ClipboardItem) {
        // 文件信息已在 ClipboardItem 中编码
        // 验证内容有效性
        guard !item.content.isEmpty else {
            panelState = .error("无法预览此内容")
            return
        }

        panelState = .showing(item)
    }

    // MARK: - Private Methods - Observers

    /// 设置内容观察者
    private func setupContentObservers() {
        // 监听剪贴板项更新通知
        NotificationCenter.default.publisher(for: .clipboardItemDidUpdate)
            .compactMap { $0.userInfo?["itemId"] as? String }
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] itemId in
                self?.handleItemUpdate(itemId: itemId)
            }
            .store(in: &cancellables)

        // 监听剪贴板项删除通知
        NotificationCenter.default.publisher(for: .clipboardItemDidDelete)
            .compactMap { $0.userInfo?["itemId"] as? String }
            .sink { [weak self] itemId in
                self?.handleItemDelete(itemId: itemId)
            }
            .store(in: &cancellables)
    }

    /// 处理剪贴板项更新
    /// - Parameter itemId: 剪贴板项 ID
    private func handleItemUpdate(itemId: String) {
        guard case .showing(let item) = panelState,
              item.id == itemId else {
            return
        }

        // 刷新预览内容
        refreshPreviewContent()
    }

    /// 处理剪贴板项删除
    /// - Parameter itemId: 剪贴板项 ID
    private func handleItemDelete(itemId: String) {
        guard case .showing(let item) = panelState,
              item.id == itemId else {
            return
        }

        // 显示删除提示
        panelState = .error("该项已被删除")
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    /// 剪贴板项已更新通知
    static let clipboardItemDidUpdate = Notification.Name("clipboardItemDidUpdate")

    /// 剪贴板项已删除通知
    static let clipboardItemDidDelete = Notification.Name("clipboardItemDidDelete")
}

//
//  PreviewPanelWindow.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import Cocoa
import SwiftUI

/// 预览面板浮动窗口管理器
@MainActor
class PreviewPanelWindowManager: ObservableObject {
    static let shared = PreviewPanelWindowManager()

    private var panel: NSPanel?
    private var hostingController: NSHostingController<PreviewPanelContentView>?
    private var mainWindow: NSWindow?
    private var windowObservers: [NSObjectProtocol] = []

    private var panelSize: NSSize {
        return NSSize(width: 400, height: 400)
    }

    private init() {
        // 私有初始化
    }

    /// 显示预览面板
    /// - Parameter item: 要预览的剪贴板项
    /// - Parameter mainWindow: 主窗口用于定位
    func showPreview(for item: ClipboardItem, mainWindow: NSWindow) {
        // 保存主窗口引用
        self.mainWindow = mainWindow

        // 如果面板不存在，创建新面板
        if panel == nil {
            createPanel()
        }

        // 更新预览内容ç
        let contentView = PreviewPanelContentView(item: item)
        hostingController?.rootView = contentView

        // 设置面板位置在主窗口右侧（顶部对齐）
        positionPanel(toRightOf: mainWindow)

        // 添加窗口移动监听
        setupWindowMoveObserver()

        // 显示面板
        panel?.orderFrontRegardless()
    }

    /// 隐藏预览面板
    func hidePreview() {
        panel?.orderOut(nil)
        removeWindowMoveObserver()
        mainWindow = nil
    }

    /// 创建预览面板
    private func createPanel() {
        let contentSize = panelSize

        // 创建 SwiftUI 视图
        let contentView = PreviewPanelContentView(item: ClipboardItem(content: "", type: .text))
        hostingController = NSHostingController(rootView: contentView)

        // 创建 NSPanel
        let newPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .retained,
            defer: false
        )

        newPanel.title = "预览"
        newPanel.isFloatingPanel = true
        newPanel.level = NSWindow.Level.floating
        newPanel.hidesOnDeactivate = false
        newPanel.worksWhenModal = true

        // 设置内容视图
        newPanel.contentViewController = hostingController
        newPanel.contentView?.frame = NSRect(origin: .zero, size: contentSize)

        // 设置透明背景（让 SwiftUI 的毛玻璃效果显示出来）
        newPanel.backgroundColor = .clear
        newPanel.isOpaque = false

        panel = newPanel
    }

    /// 定位面板到主窗口右侧（顶部对齐）
    private func positionPanel(toRightOf mainWindow: NSWindow) {
        guard let panel = panel else { return }

        let mainWindowFrame = mainWindow.frame
        let panelSize = panelSize

        // 计算预览面板的位置（主窗口右侧，顶部对齐，留一些间距）
        let spacing: CGFloat = 10
        var panelOrigin = NSPoint(
            x: mainWindowFrame.maxX + spacing,
            y: mainWindowFrame.maxY - panelSize.height  // 顶部对齐
        )

        // 确保面板在屏幕边界内
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelRightEdge = panelOrigin.x + panelSize.width

            // 如果超出屏幕右边界，切换到左侧
            if panelRightEdge > screenFrame.maxX {
                panelOrigin.x = mainWindowFrame.minX - panelSize.width - spacing
            }

            // 确保面板在屏幕顶部边界内
            if panelOrigin.y > screenFrame.maxY {
                panelOrigin.y = screenFrame.maxY
            }

            // 确保面板在屏幕底部边界内
            if panelOrigin.y < screenFrame.minY {
                panelOrigin.y = screenFrame.minY
            }
        }

        panel.setFrame(
            NSRect(origin: panelOrigin, size: panelSize),
            display: true
        )
    }

    /// 关闭预览面板
    func closePanel() {
        removeWindowMoveObserver()
        panel?.close()
        panel = nil
        hostingController = nil
        mainWindow = nil
    }

    // MARK: - Window Move Observer

    /// 设置窗口移动监听
    private func setupWindowMoveObserver() {
        // 移除旧的监听器
        removeWindowMoveObserver()

        guard let mainWindow = mainWindow else { return }

        // 监听主窗口的移动
        let moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: mainWindow,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePanelPosition()
            }
        }
        windowObservers.append(moveObserver)

        // 同时监听窗口大小变化
        let resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: mainWindow,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePanelPosition()
            }
        }
        windowObservers.append(resizeObserver)
    }

    /// 移除窗口移动监听
    private func removeWindowMoveObserver() {
        for observer in windowObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        windowObservers.removeAll()
    }

    /// 更新预览面板位置（跟随主窗口）
    private func updatePanelPosition() {
        guard let mainWindow = mainWindow, panel != nil else { return }

        // 重新定位预览面板
        positionPanel(toRightOf: mainWindow)
    }
}

// SwiftUI 内容视图
struct PreviewPanelContentView: View {
    let item: ClipboardItem

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack(spacing: 8) {
                // 类型图标
                previewTypeIcon
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.accentColor.opacity(0.09))
                    )

                // 类型标题
                Text(previewTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
            )

            Divider()

            // 预览内容
            Group {
                switch item.type {
                case .text:
                    PreviewTextView(item: item)
                case .image:
                    PreviewImageView(item: item)
                case .file:
                    PreviewFileView(item: item)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
    }

    /// 预览类型图标
    private var previewTypeIcon: some View {
        Image(systemName: {
            switch item.type {
            case .text:
                return "text.alignleft"
            case .image:
                return "photo"
            case .file:
                return "doc"
            }
        }())
    }

    /// 预览标题
    private var previewTitle: String {
        switch item.type {
        case .text:
            return "文本预览"
        case .image:
            return "图片预览"
        case .file:
            return "文件预览"
        }
    }
}

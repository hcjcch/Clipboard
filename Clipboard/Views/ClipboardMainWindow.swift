//
//  ClipboardMainWindow.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI
import AppKit

/// 剪贴板历史窗口管理器
@MainActor
class ClipboardWindowManager: ObservableObject {
    static let shared = ClipboardWindowManager()

    @Published var isWindowVisible: Bool = false
    var isShowingAlert = false  // 标记是否正在显示 alert

    private var panel: NSPanel?
    private var keyEventHandler: Any?

    private init() {}

    /// 显示窗口
    func showWindow() {
        if let existingPanel = panel {
            // 让面板成为 key window，这样失去焦点时会触发通知
            existingPanel.makeKeyAndOrderFront(nil)
        } else {
            createNewPanel()
        }
        isWindowVisible = true

        // 清空搜索状态
        ClipboardHistoryViewModel.shared.searchText = ""

        setupKeyboardMonitoring()
    }

    /// 隐藏窗口
    func hideWindow() {
        removeKeyboardMonitoring()
        panel?.orderOut(nil)
        isWindowVisible = false
    }

    /// 切换窗口显示状态
    func toggleWindow() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }

    /// 创建新面板
    private func createNewPanel() {
        let hostingView = NSHostingView(rootView: ClipboardHistoryContentView())

        // 使用 NSPanel 而不是 NSWindow，支持在全屏应用上显示
        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newPanel.title = "剪贴板历史"
        newPanel.contentViewController = NSViewController()
        newPanel.contentViewController?.view = hostingView
        newPanel.center()
        newPanel.isReleasedWhenClosed = false

        // NSPanel 关键配置
        newPanel.isFloatingPanel = true           // 浮动面板
        newPanel.becomesKeyOnlyIfNeeded = true    // 只在需要时成为 key，不激活应用
        newPanel.level = .popUpMenu               // 使用更高的窗口级别

        // 隐藏标题栏
        newPanel.titlebarAppearsTransparent = true
        newPanel.titleVisibility = .hidden
        newPanel.standardWindowButton(.closeButton)?.isHidden = true
        newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newPanel.standardWindowButton(.zoomButton)?.isHidden = true

        // 允许在所有桌面空间显示
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]

        // 失去焦点时自动隐藏（但不在显示 alert 时）
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            if !(self?.isShowingAlert ?? false) {
                self?.hideWindow()
            }
        }

        panel = newPanel
        // 让面板成为 key window，这样失去焦点时会触发通知
        newPanel.makeKeyAndOrderFront(nil)
    }

    // MARK: - 键盘事件监听

    /// 设置键盘监听
    private func setupKeyboardMonitoring() {
        // 避免重复添加
        guard keyEventHandler == nil else { return }

        keyEventHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event) ?? event
        }
    }

    /// 移除键盘监听
    private func removeKeyboardMonitoring() {
        if let handler = keyEventHandler {
            NSEvent.removeMonitor(handler)
            keyEventHandler = nil
        }
    }

    /// 处理键盘事件
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard isWindowVisible else { return event }

        let keyCode = event.keyCode
        let vm = ClipboardHistoryViewModel.shared

        // ESC: 清空搜索或关闭窗口
        if keyCode == 53 { // ESC
            if !vm.searchText.isEmpty {
                vm.searchText = ""
                return nil // 消费事件
            } else {
                hideWindow()
                return nil
            }
        }

        // Backspace: 删除字符
        if keyCode == 51 { // Backspace
            if !vm.searchText.isEmpty {
                vm.searchText.removeLast()
            }
            return nil
        }

        // 可打印字符: 添加到搜索
        if isPrintableCharacter(event), let char = event.characters {
            vm.searchText.append(char)
            return nil // 消费事件，避免系统处理
        }

        return event // 其他事件不处理
    }

    /// 判断是否为可打印字符
    private func isPrintableCharacter(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode

        // 排除功能键
        let functionKeys: Set<UInt16> = [
            53,   // ESC
            36,   // Enter
            48,   // Tab
            51,   // Backspace
            117,  // Delete
            123, 124, 125, 126, // 方向键
        ]

        if functionKeys.contains(keyCode) {
            return false
        }

        // 检查修饰键（排除 Shift）
        let modifiers = event.modifierFlags
        let hasCommand = modifiers.contains(.command)
        let hasControl = modifiers.contains(.control)
        let hasOption = modifiers.contains(.option)

        if hasCommand || hasControl || hasOption {
            return false
        }

        // 检查字符
        if let characters = event.characters, !characters.isEmpty {
            return true
        }

        return false
    }
}

/// 剪贴板历史内容视图
struct ClipboardHistoryContentView: View {
    @StateObject private var windowManager = ClipboardWindowManager.shared
    @StateObject private var viewModel = ClipboardHistoryViewModel.shared
    @State private var showClearConfirm = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // 标题栏
                titleBar

                // 历史视图
                ClipboardHistoryView()
            }
            .frame(minWidth: 400, minHeight: 500)

            // 左上角搜索输入覆盖层（覆盖标题栏）
            SearchInputOverlay(
                searchText: $viewModel.searchText,
                itemCount: viewModel.filteredItems.count
            )
            .padding(12)
        }
    }

    private var titleBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // App 图标
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "clipboard.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            // 标题
            Text("剪贴板历史")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            // 清除按钮
            Button(action: { showClearConfirm = true }) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 24, height: 24)

                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.orange.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .help("清空历史")

            // 快捷键提示
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "command")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text("⌃V")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(Color.secondary.opacity(0.1))
            )

            // 关闭按钮
            Button(action: { ClipboardWindowManager.shared.hideWindow() }) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 24, height: 24)

                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .help("关闭")
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            ZStack {
                // 毛玻璃背景
                Rectangle().fill(.ultraThinMaterial)

                // 底部边框
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        )
        .alert("清空剪贴板历史", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                Task {
                    await viewModel.clearAll()
                }
            }
        } message: {
            Text("确定要清空所有剪贴板历史记录吗？此操作不可撤销。")
        }
        .onChange(of: showClearConfirm) { _, newValue in
            ClipboardWindowManager.shared.isShowingAlert = newValue
        }
    }
}

#Preview {
    ClipboardHistoryContentView()
        .frame(width: 450, height: 600)
}

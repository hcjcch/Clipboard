//
//  ClipboardMainWindow.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

/// 剪贴板历史窗口管理器
@MainActor
class ClipboardWindowManager: ObservableObject {
    static let shared = ClipboardWindowManager()

    @Published var isWindowVisible: Bool = false
    var isShowingAlert = false  // 标记是否正在显示 alert

    private var window: NSWindow?

    private init() {}

    /// 显示窗口
    func showWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            createNewWindow()
        }
        isWindowVisible = true
    }

    /// 隐藏窗口
    func hideWindow() {
        window?.orderOut(nil)
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

    /// 创建新窗口
    private func createNewWindow() {
        let hostingView = NSHostingView(rootView: ClipboardHistoryContentView())
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "剪贴板历史"
        newWindow.contentViewController = NSViewController()
        newWindow.contentViewController?.view = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden

        // 隐藏标准窗口按钮
        newWindow.standardWindowButton(.closeButton)?.isHidden = true
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true

        // 设置窗口级别
        newWindow.level = .floating

        // 失去焦点时自动隐藏（但不在显示 alert 时）
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            // 只有在没有显示 alert 时才隐藏窗口
            if !(self?.isShowingAlert ?? false) {
                self?.hideWindow()
            }
        }

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// 剪贴板历史内容视图
struct ClipboardHistoryContentView: View {
    @StateObject private var windowManager = ClipboardWindowManager.shared
    @StateObject private var viewModel = ClipboardHistoryViewModel.shared
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            // 历史视图
            ClipboardHistoryView()
        }
        .frame(minWidth: 400, minHeight: 500)
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

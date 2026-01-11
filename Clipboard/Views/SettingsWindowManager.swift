//
//  SettingsWindowManager.swift
//  Clipboard
//
//  Created by Claude on 2025/01/10.
//

import AppKit
import SwiftUI

/// 设置窗口管理器
@MainActor
class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    private var panel: NSPanel?

    private init() {}

    /// 切换设置窗口显示/隐藏
    func toggleWindow() {
        if let existingPanel = panel, existingPanel.isVisible {
            // 如果窗口已显示，隐藏它
            existingPanel.orderOut(nil)
        } else {
            // 如果窗口未显示，显示它
            showWindow()
        }
    }

    /// 显示设置窗口
    func showWindow() {
        if let existingPanel = panel {
            // 如果窗口已存在，获取焦点
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 创建新窗口
        let hostingView = NSHostingView(rootView: SettingsView())

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newPanel.title = "设置"

        // 设置内容视图
        let viewController = NSViewController()
        viewController.view = hostingView
        newPanel.contentViewController = viewController

        // 定位窗口：水平居中，垂直方向在屏幕顶部 1/3 处
        let screen = NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let windowSize = NSSize(width: 650, height: 450)

        // 水平居中
        let x = (screenFrame.width - windowSize.width) / 2

        // 垂直方向：窗口中心在屏幕高度的 2/3 处
        let y = screenFrame.height * 2 / 3 - windowSize.height / 2

        // 使用 setFrame 确保位置生效
        let newFrame = NSRect(origin: NSPoint(x: x, y: y), size: windowSize)
        newPanel.setFrame(newFrame, display: false)

        newPanel.isReleasedWhenClosed = false

        // 监听窗口关闭通知
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            // 窗口关闭时自动保存设置
            self?.handleWindowClose()
        }

        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel = newPanel

        print("✅ Settings window opened")
    }

    /// 处理窗口关闭事件
    private func handleWindowClose() {
        // 窗口关闭时，设置已自动保存（通过 UserSettingsService）
        // 这里可以添加额外的清理逻辑
        print("✅ Settings window closed, settings auto-saved")
        panel = nil
    }

    /// 检查设置窗口是否可见
    var isWindowVisible: Bool {
        guard let existingPanel = panel else { return false }
        return existingPanel.isVisible
    }
}

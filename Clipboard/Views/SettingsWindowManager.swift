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

    /// 显示设置窗口
    func showWindow() {
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 使用 NSHostingView 而不是 NSHostingController
        let hostingView = NSHostingView(rootView: SettingsView())

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
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
        // 注意：必须在设置内容视图之后设置位置
        if let mainScreen = NSScreen.screens.first {
            let screenFrame = mainScreen.visibleFrame
            let windowSize = NSSize(width: 500, height: 400)

            print("主屏幕信息:")
            print("  visibleFrame: \(screenFrame)")
            print("  窗口大小: \(windowSize)")

            // 水平居中
            let x = (screenFrame.width - windowSize.width) / 2

            // 垂直方向：窗口中心在屏幕高度的 2/3 处（即从顶部算起的 1/3 处）
            let y = screenFrame.height * 2 / 3 - windowSize.height / 2

            print("  计算的窗口位置: x=\(x), y=\(y)")

            // 使用 setFrame 而不是 setFrameOrigin，确保位置生效
            let newFrame = NSRect(origin: NSPoint(x: x, y: y), size: windowSize)
            newPanel.setFrame(newFrame, display: false)
        } else {
            // 如果无法获取屏幕信息，则居中显示
            newPanel.center()
        }

        newPanel.isReleasedWhenClosed = false

        // 监听窗口关闭通知
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            self?.panel = nil
        }

        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel = newPanel
    }
}

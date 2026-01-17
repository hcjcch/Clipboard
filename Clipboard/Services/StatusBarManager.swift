//
//  StatusBarManager.swift
//  Clipboard
//
//  Created by Claude on 2025/01/10.
//

import AppKit
import SwiftUI

/// 菜单栏管理器
@MainActor
class StatusBarManager {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private let localizationService = LocalizationService.shared

    private init() {
        setupStatusBar()

        // 监听语言变化通知
        NotificationCenter.default.addObserver(
            forName: .init("LanguageDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMenu()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 设置菜单栏图标
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // 使用 SF Symbol 图标
            if let icon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "剪贴板") {
                icon.isTemplate = true  // 自动适应亮色/暗色模式
                button.image = icon
            } else {
                // 如果 SF Symbol 不可用，使用文字作为后备
                button.title = "📋"
            }
        }

        setupMenu()
    }

    /// 设置右键菜单
    private func setupMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "statusbar.toggle_history".localizedString(),
            action: #selector(toggleWindow),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "statusbar.settings".localizedString(),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "statusbar.quit".localizedString(),
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    /// 刷新菜单（语言切换时调用）
    func refreshMenu() {
        setupMenu()
    }

    /// 切换窗口显示/隐藏
    @objc func toggleWindow() {
        ClipboardWindowManager.shared.toggleWindow()
    }

    /// 打开设置窗口
    @objc func openSettings() {
        SettingsWindowManager.shared.showWindow()
    }

    /// 退出应用
    @objc func quit() {
        NSApp.terminate(nil)
    }
}

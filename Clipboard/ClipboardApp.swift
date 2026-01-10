//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 设置空场景，因为我们将使用自定义窗口
        Settings {
            EmptyView()
        }
    }
}

/// 应用委托
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 禁用状态恢复
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows" : false])

        setupApp()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 当最后一个窗口关闭时不退出应用
        // 我们使用快捷键来重新显示窗口
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 停止剪贴板监听
        ClipboardMonitorService.shared.stopMonitoring()

        // 取消快捷键
        hotKeyManager?.unregister()
    }

    /// 设置应用
    private func setupApp() {
        // 1. 启动剪贴板监听
        ClipboardMonitorService.shared.startMonitoring()

        // 2. 设置全局快捷键
        setupHotKey()

        // 3. 隐藏 Dock 图标，作为菜单栏应用运行
        NSApp.setActivationPolicy(.accessory)

        // 4. 初始化菜单栏图标
        _ = StatusBarManager.shared

        print("应用启动完成")
        print("快捷键: ⌃⌘V 呼出/隐藏剪贴板历史")
    }

    /// 设置全局快捷键
    private func setupHotKey() {
        let hotKeyManager = HotKeyManager.shared
        self.hotKeyManager = hotKeyManager

        // 设置快捷键回调
        hotKeyManager.onHotKeyPressed = { [weak self] in
            self?.handleHotKeyPressed()
        }

        // 注册 ⌃⌘V 快捷键
        hotKeyManager.register(hotKey: .controlCommandV)
    }

    /// 处理快捷键按下
    private func handleHotKeyPressed() {
        ClipboardWindowManager.shared.toggleWindow()
    }
}

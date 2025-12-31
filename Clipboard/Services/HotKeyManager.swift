//
//  HotKeyManager.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Carbon

/// 快捷键定义
struct HotKey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let displayName: String

    // 控制键 + 命令键 + V
    static let controlCommandV = HotKey(
        keyCode: UInt32(kVK_ANSI_V),  // V键
        modifiers: UInt32(cmdKey | controlKey),
        displayName: "⌃⌘V"
    )
}

/// 全局快捷键管理器
@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    // 快捷键按下时的回调
    var onHotKeyPressed: (() -> Void)?

    private init() {}

    /// 注册全局快捷键
    func register(hotKey: HotKey) {
        // 如果已经注册，先取消
        unregister()

        var hotKeyID = EventHotKeyID(signature: FOUR_CHAR_CODE("HCKY"), id: 1)
        var hotKeyParams = EventHotKeyRef(bitPattern: 0)

        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyParams
        )

        guard status == noErr, let hotKeyRef = hotKeyParams else {
            print("注册快捷键失败: \(status)")
            return
        }

        self.hotKeyRef = hotKeyRef

        // 安装事件处理器
        installEventHandler()

        print("已注册快捷键: \(hotKey.displayName)")
    }

    /// 取消快捷键注册
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        print("已取消快捷键注册")
    }

    /// 安装事件处理器
    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        var eventHandlerRef: EventHandlerRef?
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else {
                    return noErr
                }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                // 在主线程执行回调
                Task { @MainActor in
                    manager.handleHotKeyEvent()
                }

                return noErr
            },
            1,
            &eventSpec,
            userData,
            &eventHandlerRef
        )

        guard status == noErr, let eventHandlerRef = eventHandlerRef else {
            print("安装事件处理器失败: \(status)")
            return
        }

        self.eventHandlerRef = eventHandlerRef
    }

    /// 处理快捷键事件
    private func handleHotKeyEvent() {
        onHotKeyPressed?()
    }
}

// 辅助函数：创建四字符码
private func FOUR_CHAR_CODE(_ str: String) -> FourCharCode {
    let chars = Array(str.utf8)
    precondition(chars.count == 4, "FourCharCode must be exactly 4 characters")

    return FourCharCode(chars[0]) << 24 |
           FourCharCode(chars[1]) << 16 |
           FourCharCode(chars[2]) << 8 |
           FourCharCode(chars[3])
}

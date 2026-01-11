import Foundation
import Carbon

/// 系统保留快捷键验证器
struct SystemHotKeyValidator: Sendable {
    /// 系统保留快捷键集合
    private let reservedKeys: Set<SystemReservedKey>

    init() {
        // 初始化约 20 个常见 macOS 系统快捷键
        let cmd = UInt32(cmdKey)
        let shift = UInt32(shiftKey)
        let opt = UInt32(optionKey)

        var keys: [SystemReservedKey] = []

        // 基础系统快捷键
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_Q), modifiers: cmd)) // ⌘Q 退出
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_Delete), modifiers: cmd)) // ⌘⌫ 删除
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_W), modifiers: cmd)) // ⌘W 关闭窗口
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_N), modifiers: cmd)) // ⌘N 新建
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_O), modifiers: cmd)) // ⌘O 打开
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_S), modifiers: cmd)) // ⌘S 保存
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_Z), modifiers: cmd)) // ⌘Z 撤销
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_Z), modifiers: cmd | shift)) // ⇧⌘Z 重做
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_X), modifiers: cmd)) // ⌘X 剪切
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_C), modifiers: cmd)) // ⌘C 复制
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_V), modifiers: cmd)) // ⌘V 粘贴
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_A), modifiers: cmd)) // ⌘A 全选
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_F), modifiers: cmd)) // ⌘F 查找
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_P), modifiers: cmd)) // ⌘P 打印
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_T), modifiers: cmd)) // ⌘T 新标签页
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_Comma), modifiers: cmd)) // ⌘, 打开设置
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_H), modifiers: cmd)) // ⌘H 隐藏应用
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_H), modifiers: cmd | opt)) // ⌥⌘H 隐藏其他应用
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_ANSI_M), modifiers: cmd)) // ⌘M 最小化
        keys.append(SystemReservedKey(keyCode: UInt32(kVK_Space), modifiers: cmd)) // ⌘Space Spotlight

        self.reservedKeys = Set(keys)

        print("✅ SystemHotKeyValidator initialized with \(reservedKeys.count) reserved keys")
    }

    /// 检查快捷键是否是系统保留键
    func isSystemReserved(hotKey: HotKeyDefinition) -> Bool {
        let key = SystemReservedKey(keyCode: hotKey.keyCode, modifiers: normalizeModifiers(hotKey.modifiers))
        let isReserved = reservedKeys.contains(key)

        if isReserved {
            print("⚠️ HotKey \(hotKey.displayName) is system reserved")
        }

        return isReserved
    }

    /// 标准化修饰键（忽略 Caps Lock 等）
    private func normalizeModifiers(_ modifiers: UInt32) -> UInt32 {
        // 只保留 cmdKey、controlKey、optionKey、shiftKey
        let mask = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        return modifiers & mask
    }
}

/// 系统保留键结构
private struct SystemReservedKey: Hashable, Sendable {
    let keyCode: UInt32
    let modifiers: UInt32
}

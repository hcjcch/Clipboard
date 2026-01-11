import Foundation
import Carbon

/// 表示一个全局快捷键，包含 keyCode、modifiers 和显示名称
struct HotKeyDefinition: Equatable, Codable, Sendable {
    /// Carbon 框架的虚拟键码
    let keyCode: UInt32

    /// 修饰键标志位（cmdKey、controlKey、optionKey、shiftKey）
    let modifiers: UInt32

    /// 用户友好的显示名称（如 "⌃⌘V"）
    let displayName: String

    /// 默认快捷键：⌘⌃V
    static let controlCommandV = HotKeyDefinition(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | controlKey),
        displayName: "⌘⌃V"
    )

    /// 验证快捷键是否有效（至少包含一个修饰键）
    var isValid: Bool {
        let modifierMask = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        return (modifiers & modifierMask) != 0
    }
}

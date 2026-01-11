import Foundation

/// 用户设置的数据模型，包含所有用户可自定义的设置项
struct UserSettings: Codable, Sendable {
    /// 用户自定义的全局快捷键
    var customHotKey: HotKeyDefinition

    /// 是否使用自定义快捷键（false 表示使用默认）
    var isCustomHotKeyEnabled: Bool

    /// 默认设置
    static let `default` = UserSettings(
        customHotKey: .controlCommandV,
        isCustomHotKeyEnabled: false
    )
}

import SwiftUI

/// 设置界面左侧导航的选项枚举
enum SettingsOption: String, CaseIterable, Identifiable, Sendable {
    /// 快捷键设置选项
    case hotkey
    /// 语言设置选项
    case language

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hotkey: return LString("settings.hotkey")
        case .language: return LString("settings.language.title")
        }
    }

    var iconName: String {
        switch self {
        case .hotkey: return "keyboard"
        case .language: return "globe"
        }
    }
}

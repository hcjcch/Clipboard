import SwiftUI

/// 设置界面左侧导航的选项枚举
enum SettingsOption: String, CaseIterable, Identifiable, Sendable {
    /// 快捷键设置选项
    case hotkey
    /// 历史记录设置选项
    case history
    /// 语言设置选项
    case language

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hotkey: return LString("settings.hotkey")
        case .history: return LString("settings.history")
        case .language: return LString("settings.language.title")
        }
    }

    var iconName: String {
        switch self {
        case .hotkey: return "keyboard"
        case .history: return "clock.arrow.circlepath"
        case .language: return "globe"
        }
    }
}

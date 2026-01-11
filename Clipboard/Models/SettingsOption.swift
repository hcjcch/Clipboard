import SwiftUI

/// 设置界面左侧导航的选项枚举
enum SettingsOption: String, CaseIterable, Identifiable, Sendable {
    /// 快捷键设置选项
    case hotkey

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hotkey: return "快捷键"
        }
    }

    var iconName: String {
        switch self {
        case .hotkey: return "keyboard"
        }
    }
}

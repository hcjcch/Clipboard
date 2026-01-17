import Foundation

/// 应用支持的语言类型
enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    /// 简体中文
    case simplifiedChinese = "zh-Hans"
    /// 英文
    case english = "en"

    /// 唯一标识符（用于 ForEach）
    var id: String { rawValue }

    /// Locale 标识符，用于创建 Locale 对象
    var localeIdentifier: String {
        rawValue
    }

    /// 本地化的语言显示名称
    /// - Note: 从 Localizable.strings 中读取对应的 key
    /// - Chinese UI: "简体中文", English UI: "Simplified Chinese"
    var displayName: String {
        switch self {
        case .simplifiedChinese:
            return "language.simplified_chinese".localizedString()
        case .english:
            return "language.english".localizedString()
        }
    }
}

//
//  LocalizationHelper.swift
//  Clipboard
//
//  Created by Claude on 2025/01/17.
//

import SwiftUI

/// UserDefaults 键名（与 LocalizationService 保持一致）
private enum LocalizationKeys {
    static let appLanguage = "appLanguage"
}

/// 从 UserDefaults 获取当前应用语言
/// - Returns: 当前应用语言的 localeIdentifier
private func getCurrentLocaleIdentifier() -> String {
    if let savedRaw = UserDefaults.standard.string(forKey: LocalizationKeys.appLanguage),
       let savedLanguage = AppLanguage(rawValue: savedRaw) {
        return savedLanguage.localeIdentifier
    }

    // 如果没有保存的语言设置，检测系统语言
    let preferredLanguages = Locale.preferredLanguages
    if let firstLanguage = preferredLanguages.first, firstLanguage.hasPrefix("zh") {
        return AppLanguage.simplifiedChinese.localeIdentifier
    }

    return AppLanguage.english.localeIdentifier
}

/// 本地化字符串辅助函数
/// - Parameter key: 本地化 key（在 Localizable.strings 中定义）
/// - Returns: 本地化后的字符串，如果 key 不存在则返回 key 本身
func LString(_ key: String) -> String {
    key.localizedString()
}

/// 本地化字符串视图构造函数
/// - Parameter key: 本地化 key（在 Localizable.strings 中定义）
/// - Returns: Text 视图，显示本地化后的字符串
func LText(_ key: String) -> Text {
    Text(key.localizedString())
}

extension String {
    /// 获取当前语言下的本地化字符串
    /// - Parameter localeIdentifier: locale 标识符，默认使用当前应用设置的语言
    /// - Returns: 本地化后的字符串，如果 key 不存在则返回 key 本身
    func localizedString(localeIdentifier: String? = nil) -> String {
        let identifier = localeIdentifier ?? getCurrentLocaleIdentifier()

        // 根据 localeIdentifier 获取对应的 lproj 目录名
        // zh-Hans, zh-CN -> zh-Hans
        // en -> en
        let language: String
        if identifier == "zh-Hans" || identifier == "zh-CN" || identifier.hasPrefix("zh") {
            language = "zh-Hans"
        } else {
            language = "en"
        }

        // 从主 bundle 中查找对应语言的 lproj 目录
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle.localizedString(forKey: self, value: self, table: nil)
        }

        // 如果找不到对应的 bundle，返回 key 本身
        return self
    }
}

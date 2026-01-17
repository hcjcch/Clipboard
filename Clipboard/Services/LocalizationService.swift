import Foundation
import Observation

/// 本地化服务 - 单例
@MainActor
@Observable
final class LocalizationService {
    /// 单例实例
    static let shared = LocalizationService()

    /// UserDefaults 键名
    private enum Keys {
        static let appLanguage = "appLanguage"
    }

    /// 当前应用语言
    private(set) var currentLanguage: AppLanguage = .english {
        didSet {
            saveLanguage()
        }
    }

    /// 当前语言对应的 Locale 对象
    var locale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier)
    }

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadSavedLanguage()
    }

    /// 从 UserDefaults 加载保存的语言
    private func loadSavedLanguage() {
        if let savedRaw = userDefaults.string(forKey: Keys.appLanguage),
           let savedLanguage = AppLanguage(rawValue: savedRaw) {
            currentLanguage = savedLanguage
            print("✅ Localization loaded: \(currentLanguage.displayName)")
        } else {
            // 首次启动，检测系统语言
            currentLanguage = detectSystemLanguage()
            print("✅ Localization initialized (system): \(currentLanguage.displayName)")
        }
    }

    /// 保存当前语言到 UserDefaults
    private func saveLanguage() {
        userDefaults.set(currentLanguage.rawValue, forKey: Keys.appLanguage)
        print("✅ Localization saved: \(currentLanguage.displayName)")
    }

    /// 设置应用语言
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        // 发送通知，让 UI 更新 locale
        NotificationCenter.default.post(name: .init("LanguageDidChange"), object: nil)
    }

    /// 检测系统语言
    /// - Returns: 支持的语言，如果不支持则返回英文作为默认
    func detectSystemLanguage() -> AppLanguage {
        let preferredLanguages = Locale.preferredLanguages
        guard let firstLanguage = preferredLanguages.first else {
            return .english
        }

        // 检查是否为中文（包括所有变体：zh-Hans, zh-Hant, zh-CN 等）
        if firstLanguage.hasPrefix("zh") {
            return .simplifiedChinese
        }

        // 其他语言默认使用英文
        return .english
    }
}

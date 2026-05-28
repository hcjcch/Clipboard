import Foundation
import Observation

/// 用户设置的持久化和读取服务
@MainActor
@Observable
final class UserSettingsService {
    /// 单例实例
    static let shared = UserSettingsService()

    /// UserDefaults 键名
    private enum Keys {
        static let customHotKeyKeyCode = "customHotKeyKeyCode"
        static let customHotKeyModifiers = "customHotKeyModifiers"
        static let customHotKeyDisplayName = "customHotKeyDisplayName"
        static let isCustomHotKeyEnabled = "isCustomHotKeyEnabled"
        static let maxHistoryItems = "maxHistoryItems"
    }

    /// 当前用户设置
    private(set) var userSettings: UserSettings = .default {
        didSet {
            saveUserSettings()
        }
    }

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadUserSettings()
    }

    /// 从 UserDefaults 加载用户设置
    private func loadUserSettings() {
        let isEnabled = userDefaults.bool(forKey: Keys.isCustomHotKeyEnabled)

        if isEnabled {
            let keyCode = userDefaults.object(forKey: Keys.customHotKeyKeyCode) as? UInt32 ?? HotKeyDefinition.controlCommandV.keyCode
            let modifiers = userDefaults.object(forKey: Keys.customHotKeyModifiers) as? UInt32 ?? HotKeyDefinition.controlCommandV.modifiers
            let displayName = userDefaults.string(forKey: Keys.customHotKeyDisplayName) ?? HotKeyDefinition.controlCommandV.displayName
            let maxHistoryItems = userDefaults.object(forKey: Keys.maxHistoryItems) as? Int ?? UserSettings.default.maxHistoryItems

            userSettings = UserSettings(
                customHotKey: HotKeyDefinition(keyCode: keyCode, modifiers: modifiers, displayName: displayName),
                isCustomHotKeyEnabled: true,
                maxHistoryItems: maxHistoryItems
            )
        } else {
            var settings = UserSettings.default
            settings.maxHistoryItems = userDefaults.object(forKey: Keys.maxHistoryItems) as? Int ?? UserSettings.default.maxHistoryItems
            userSettings = settings
        }

        print("✅ UserSettings loaded: \(userSettings.customHotKey.displayName), enabled: \(userSettings.isCustomHotKeyEnabled)")
    }

    /// 保存用户设置到 UserDefaults
    func saveUserSettings() {
        userDefaults.set(userSettings.customHotKey.keyCode, forKey: Keys.customHotKeyKeyCode)
        userDefaults.set(userSettings.customHotKey.modifiers, forKey: Keys.customHotKeyModifiers)
        userDefaults.set(userSettings.customHotKey.displayName, forKey: Keys.customHotKeyDisplayName)
        userDefaults.set(userSettings.isCustomHotKeyEnabled, forKey: Keys.isCustomHotKeyEnabled)
        userDefaults.set(userSettings.maxHistoryItems, forKey: Keys.maxHistoryItems)

        print("✅ UserSettings saved: \(userSettings.customHotKey.displayName), enabled: \(userSettings.isCustomHotKeyEnabled)")
    }

    /// 更新用户自定义快捷键
    func updateCustomHotKey(_ hotKey: HotKeyDefinition) {
        userSettings.customHotKey = hotKey
        userSettings.isCustomHotKeyEnabled = true

        // 发送通知，让 UI 更新快捷键显示
        NotificationCenter.default.post(name: .init("HotKeyDidChange"), object: nil)
    }

    /// 更新最大历史记录数量
    func updateMaxHistoryItems(_ maxItems: Int) {
        userSettings.maxHistoryItems = maxItems
        NotificationCenter.default.post(name: .init("HistorySettingsDidChange"), object: nil)
    }

    /// 恢复默认快捷键
    func resetToDefault() {
        let currentMaxHistoryItems = userSettings.maxHistoryItems
        userSettings = UserSettings(
            customHotKey: .controlCommandV,
            isCustomHotKeyEnabled: false,
            maxHistoryItems: currentMaxHistoryItems
        )

        // 发送通知，让 UI 更新快捷键显示
        NotificationCenter.default.post(name: .init("HotKeyDidChange"), object: nil)
    }
}

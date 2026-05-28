import Foundation
import Observation

/// 设置界面的视图模型，管理 UI 状态
@MainActor
@Observable
final class SettingsViewModel {
    /// 单例实例
    static let shared = SettingsViewModel()

    /// 当前选中的设置选项
    var selectedOption: SettingsOption = .hotkey

    /// 用户设置（从 UserSettingsService 读取）
    private(set) var userSettings: UserSettings = .default

    /// UI 状态
    private(set) var isRecordingHotKey: Bool = false
    private(set) var hotKeyError: HotKeyError?

    /// 系统快捷键验证器
    private let systemHotKeyValidator = SystemHotKeyValidator()

    private init() {
        loadUserSettings()
    }

    /// 从 UserSettingsService 加载用户设置
    private func loadUserSettings() {
        userSettings = UserSettingsService.shared.userSettings
    }

    /// 更新自定义快捷键
    func updateCustomHotKey(_ hotKey: HotKeyDefinition) {
        // 验证快捷键是否有效
        guard hotKey.isValid else {
            hotKeyError = .noModifier
            print("❌ 无效快捷键：缺少修饰键")
            return
        }

        // 检查是否是系统保留键
        guard !systemHotKeyValidator.isSystemReserved(hotKey: hotKey) else {
            hotKeyError = .systemReserved
            print("❌ 快捷键与系统保留键冲突")
            return
        }

        // 验证通过，更新快捷键
        hotKeyError = nil
        userSettings.customHotKey = hotKey
        userSettings.isCustomHotKeyEnabled = true

        // 更新 UserSettingsService
        UserSettingsService.shared.updateCustomHotKey(hotKey)

        // 立即应用到 HotKeyManager
        HotKeyManager.shared.updateHotKey(hotKey)

        print("✅ 快捷键已更新: \(hotKey.displayName)")
    }

    /// 恢复默认快捷键
    func resetToDefault() {
        hotKeyError = nil
        userSettings.customHotKey = .controlCommandV
        userSettings.isCustomHotKeyEnabled = false

        // 更新 UserSettingsService
        UserSettingsService.shared.resetToDefault()

        // 更新 HotKeyManager
        HotKeyManager.shared.resetToDefault()

        print("✅ 已恢复默认快捷键")
    }

    /// 更新最大历史记录数量
    func updateMaxHistoryItems(_ maxItems: Int) {
        userSettings.maxHistoryItems = maxItems
        UserSettingsService.shared.updateMaxHistoryItems(maxItems)

        Task {
            do {
                try await DatabaseService.shared.cleanupOldItems()
                ClipboardHistoryViewModel.shared.loadItems()
            } catch {
                print("❌ 清理历史记录失败: \(error.localizedDescription)")
            }
        }
    }

    /// 开始录制快捷键
    func startRecording() {
        isRecordingHotKey = true
        hotKeyError = nil
    }

    /// 停止录制快捷键
    func stopRecording() {
        isRecordingHotKey = false
    }

    /// 清除错误
    func clearError() {
        hotKeyError = nil
    }
}

/// 快捷键错误类型
enum HotKeyError: Error, LocalizedError {
    case noModifier
    case systemReserved

    var errorDescription: String? {
        switch self {
        case .noModifier:
            return "请使用有效的组合键（至少包含一个修饰键）"
        case .systemReserved:
            return "此快捷键已被系统使用，请选择其他组合键"
        }
    }
}

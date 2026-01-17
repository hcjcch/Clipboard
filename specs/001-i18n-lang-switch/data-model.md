# Data Model: 多语言切换功能

**Feature**: 多语言切换功能
**Date**: 2025-01-17
**Phase**: Phase 1 - Design & Contracts

---

## 实体概述

本功能涉及以下核心实体：

1. **AppLanguage** - 应用支持的语言枚举
2. **LocalizationService** - 本地化服务（单例）
3. **UserSettings (扩展)** - 用户设置模型，新增语言字段

---

## 1. AppLanguage (枚举)

**描述**: 定义应用支持的语言类型

**文件**: `Clipboard/Models/AppLanguage.swift`

### 属性

| 名称 | 类型 | 描述 | 验证规则 |
|------|------|------|----------|
| `rawValue` | `String` | 枚举的原始值，用于持久化 | 必须是有效的 locale 标识符 |
| `id` | `String` | 唯一标识符（ForEach 使用） | 等于 rawValue |

### 枚举 Cases

| Case | rawValue | localeIdentifier | 描述 |
|------|----------|------------------|------|
| `simplifiedChinese` | `"zh-Hans"` | `"zh-Hans"` | 简体中文 |
| `english` | `"en"` | `"en"` | 英文 |

### 计算属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `localeIdentifier` | `String` | 返回对应的 locale 标识符，用于创建 Locale 对象 |
| `displayName` | `String` | 返回本地化的语言显示名称（从 Localizable.strings 读取） |

### 关系

- **被使用于**: `LocalizationService.currentLanguage`
- **持久化到**: `UserDefaults` (通过 rawValue)

### Swift 代码定义

```swift
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
            return String(localized: "language.simplified_chinese")
        case .english:
            return String(localized: "language.english")
        }
    }
}
```

---

## 2. LocalizationService (单例服务)

**描述**: 管理应用当前语言状态的单例服务

**文件**: `Clipboard/Services/LocalizationService.swift`

### 职责

1. 维护当前应用语言状态
2. 提供语言切换接口
3. 检测系统语言并初始化默认语言
4. 持久化用户语言选择到 UserDefaults

### 属性

| 名称 | 类型 | 访问级别 | 描述 |
|------|------|----------|------|
| `shared` | `LocalizationService` | `static` | 单例实例 |
| `currentLanguage` | `AppLanguage` | `private(set)` | 当前选中的语言，@Published 自动通知观察者 |
| `locale` | `Locale` | (计算属性) | 当前语言对应的 Locale 对象 |

### 方法

| 方法 | 参数 | 返回值 | 描述 |
|------|------|--------|------|
| `setLanguage(_:)` | `AppLanguage` | `Void` | 设置应用语言，持久化到 UserDefaults |
| `detectSystemLanguage()` | - | `AppLanguage` | 检测系统语言，返回支持的语言或默认英文 |

### 状态转换

```
[应用启动]
    ↓
[检测 UserDefaults 是否有保存的语言]
    ↓
    ├── 有 ──→ 加载保存的语言 ──→ currentLanguage = 保存值
    │
    └── 无 ──→ detectSystemLanguage() ──→ currentLanguage = 检测结果

[用户切换语言]
    ↓
setLanguage(新语言)
    ↓
currentLanguage = 新语言 (触发 @Published)
    ↓
保存到 UserDefaults
```

### 通知机制

- **@Published 自动通知**: `currentLanguage` 变化时自动通知所有观察者
- **环境值传播**: 通过 `.environment(\.locale)` 传播到所有 SwiftUI 视图

### 与其他组件的关系

| 组件 | 关系类型 | 描述 |
|------|----------|------|
| `AppLanguage` | 依赖 | 使用 AppLanguage 枚举作为 currentLanguage 的类型 |
| `UserDefaults` | 持久化 | 将语言选择持久化到 UserDefaults |
| `SettingsViewModel` | 被依赖 | ViewModel 依赖 LocalizationService 获取和设置语言 |

### Swift 代码定义

```swift
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
```

---

## 3. UserSettings (扩展)

**描述**: 用户设置数据模型，新增语言相关字段

**文件**: `Clipboard/Models/UserSettings.swift` (修改现有文件)

### 新增属性

| 名称 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `selectedLanguage` | `AppLanguage` | `.english` | 用户选择的应用语言 |

### 修改后的结构

```swift
import Foundation

/// 用户设置的数据模型，包含所有用户可自定义的设置项
struct UserSettings: Codable, Sendable {
    /// 用户自定义的全局快捷键
    var customHotKey: HotKeyDefinition

    /// 是否使用自定义快捷键（false 表示使用默认）
    var isCustomHotKeyEnabled: Bool

    /// 用户选择的应用语言
    var selectedLanguage: AppLanguage

    /// 默认设置
    static let `default` = UserSettings(
        customHotKey: .controlCommandV,
        isCustomHotKeyEnabled: false,
        selectedLanguage: .english  // 默认英文，会被 LocalizationService 覆盖
    )
}
```

**注意**: `selectedLanguage` 字段与 `LocalizationService` 中的 `currentLanguage` 同步。`LocalizationService` 是语言状态的权威来源，`UserSettings` 中的字段主要用于数据模型完整性。

---

## 4. SettingsViewModel (扩展)

**描述**: 设置视图模型，新增语言相关状态管理

**文件**: `Clipboard/ViewModels/SettingsViewModel.swift` (修改现有文件)

### 新增属性

| 名称 | 类型 | 描述 |
|------|------|------|
| `localizationService` | `LocalizationService` | 引用本地化服务单例 |

### 新增方法

| 方法 | 参数 | 返回值 | 描述 |
|------|------|--------|------|
| `setLanguage(_:)` | `AppLanguage` | `Void` | 委托给 LocalizationService.setLanguage() |

---

## 5. 本地化字符串资源

**描述**: 包含所有界面文字的中英文翻译

**文件**:
- `Clipboard/Resources/zh-Hans.lproj/Localizable.strings`
- `Clipboard/Resources/en.lproj/Localizable.strings`

### 字符串清单

| Key | 中文 (zh-Hans) | 英文 (en) | 使用位置 |
|-----|----------------|-----------|----------|
| `language.english` | English | English | 语言选择器 |
| `language.simplified_chinese` | 简体中文 | Simplified Chinese | 语言选择器 |
| `settings.language.title` | 语言 | Language | 设置页面标题 |
| `settings.language.description` | 选择应用界面的显示语言 | Choose the display language for the app | 设置页面描述 |

---

## ER 图 (实体关系图)

```
┌─────────────────────┐
│   AppLanguage       │
│   (enum)            │
├─────────────────────┤
│ + rawValue: String  │
│ + id: String        │
│ + displayName: String│
└──────────┬──────────┘
           │
           │ 依赖
           ↓
┌─────────────────────────────────────┐
│   LocalizationService               │
│   (observable, singleton)           │
├─────────────────────────────────────┤
│ + shared: LocalizationService       │
│ + currentLanguage: AppLanguage      │◄──────── @Published
│ + locale: Locale (computed)         │
├─────────────────────────────────────┤
│ - setLanguage(_: AppLanguage)       │
│ - detectSystemLanguage()            │
└──────────┬──────────────────────────┘
           │
           │ 持久化到
           ↓
    ┌──────────────┐
    │ UserDefaults │
    │ Key:         │
    │ "appLanguage"│
    └──────────────┘

┌─────────────────────────────────────┐
│   SettingsViewModel                 │
├─────────────────────────────────────┤
│ + localizationService: LocalizationService│
└─────────────────────────────────────┘
```

---

## 数据流图

```
[应用启动]
    ↓
[LocalizationService.shared.init]
    ↓
[loadSavedLanguage()]
    ├── UserDefaults 有保存 → 使用保存值
    └── UserDefaults 无保存 → detectSystemLanguage()
    ↓
[currentLanguage 设置完成]
    ↓
[.environment(\.locale, locale)]
    ↓
[所有 SwiftUI 视图自动使用当前语言]

[用户在设置中选择新语言]
    ↓
[SettingsViewModel.setLanguage()]
    ↓
[LocalizationService.setLanguage()]
    ↓
[currentLanguage = 新语言] → @Published 触发
    ↓
[locale 计算属性变化]
    ↓
[SwiftUI 环境值更新]
    ↓
[所有 Text("key") 自动刷新]
```

---

## 验证规则总结

1. **AppLanguage**
   - rawValue 必须是有效的 locale 标识符（"zh-Hans" 或 "en"）

2. **LocalizationService**
   - 必须是单例，全局唯一实例
   - currentLanguage 变化必须自动保存到 UserDefaults
   - 应用启动时必须优先加载保存的语言

3. **UserDefaults 持久化**
   - 键名: "appLanguage"
   - 值类型: String (AppLanguage.rawValue)
   - 默认值: 无（首次启动时通过系统语言检测确定）

---

## 并发与线程安全

- **@MainActor**: LocalizationService 标记为 @MainActor，确保所有操作在主线程执行
- **@Observable**: Swift 6.0 的观察者模式，自动处理线程安全
- **UserDefaults**: 线程安全，可直接从任意线程读取（但本服务通过 @MainActor 确保主线程访问）

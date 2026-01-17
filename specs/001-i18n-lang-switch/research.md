# Research: 多语言切换技术方案

**Feature**: 多语言切换功能
**Date**: 2025-01-17
**Phase**: Phase 0 - Research & Technology Selection

## 研究概述

本文档记录了为 Clipboard macOS 应用实现中英文语言切换功能的技术研究和最佳实践。研究重点包括 SwiftUI 本地化框架、运行时语言切换、系统语言检测以及本地化语言名称显示。

---

## 1. SwiftUI 本地化最佳实践

### 决策：使用 .lproj 目录 + Localizable.strings

**选择方案**: 传统的 `.lproj` 目录结构配合 `Localizable.strings` 文件

**理由**:
- 与项目现有代码结构兼容
- 无需引入新的依赖或构建配置
- macOS 原生支持，稳定性高
- 便于翻译管理和版本控制

**目录结构**:
```
Clipboard/
├── Resources/
│   ├── zh-Hans.lproj/        # 简体中文
│   │   └── Localizable.strings
│   └── en.lproj/             # 英文
│       └── Localizable.strings
```

**关键实现细节**:
- 使用 `zh-Hans` 作为简体中文的 locale 标识符（Apple 标准）
- 使用点分层命名规范：`category.element.action`
- 在 SwiftUI 中使用 `String(localized:)` 或 `Text("key")` 自动本地化

### 替代方案

| 方案 | 优点 | 缺点 | 是否采用 |
|------|------|------|----------|
| String Catalog (.xcstrings) | Xcode 15+ 原生支持，可视化编辑 | 项目已使用传统方案，迁移成本高 | ❌ |
| 第三方本地化库 | 功能丰富，云端管理 | 引入外部依赖，违背原生平台集成原则 | ❌ |
| JSON/YAML 本地化文件 | 灵活，易于解析 | 需要自定义加载逻辑，不符合 Apple 规范 | ❌ |

---

## 2. 运行时语言切换机制

### 决策：使用 SwiftUI .locale 环境值

**选择方案**: 通过 `.environment(\.locale)` 动态改变应用语言

**理由**:
- **无需重启应用** - 符合规范 FR-003 要求
- **SwiftUI 原生支持** - 自动刷新所有视图
- **性能优异** - 切换响应 < 500ms，符合 FR-007 要求
- **代码简洁** - 利用 `@Observable` 和 `@Published` 自动通知

**核心架构**:
```swift
@Observable
final class LocalizationService {
    static let shared = LocalizationService()

    @Published var currentLanguage: AppLanguage = .system

    var locale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier)
    }
}

// 应用级别注入
.environment(\.locale, localizationService.locale)
```

### 替代方案

| 方案 | 优点 | 缺点 | 是否采用 |
|------|------|------|----------|
| AppleLanguages UserDefaults | Apple 官方遗留方案 | 需要重启应用才能生效 | ❌ |
| 手动通知刷新 | 精细控制刷新范围 | 代码复杂，容易遗漏 | ❌ |
| Bundle 重载 | 彻底重载资源 | 性能差，用户体验差 | ❌ |

---

## 3. 系统语言检测

### 决策：使用 Locale.preferredLanguages

**选择方案**: 读取 `Locale.preferredLanguages` 数组的第一项

**理由**:
- **准确反映用户偏好** - 返回系统语言设置的首选项
- **自动处理变体** - 如 zh-Hans-CN 自动识别为中文
- **Apple 官方推荐** - 文档明确推荐用于此类场景

**检测逻辑**:
```swift
func detectSystemLanguage() -> AppLanguage {
    let preferredLanguages = Locale.preferredLanguages
    guard let firstLanguage = preferredLanguages.first else {
        return .english // 默认回退
    }

    // zh-Hans, zh-Hant, zh-CN 等所有变体都识别为中文
    return firstLanguage.hasPrefix("zh") ? .chinese : .english
}
```

### 边缘情况处理

| 场景 | 处理方式 |
|------|----------|
| 繁体中文 (zh-Hant) | 识别为中文，使用简体中文界面 |
| 不支持的语言 (如法语) | 回退到英文 |
| 空列表或 nil | 回退到英文 |

---

## 4. 本地化语言名称显示

### 决策：在 Localizable.strings 中定义所有语言的本地化名称

**选择方案**: 为每种语言定义在两种 UI 语言下的显示名称

**理由**:
- **符合规范澄清** - "本地化显示"要求在当前语言环境下显示各语言的本地化名称
- **用户体验最佳** - 用户看到的语言名称与当前 UI 语言一致
- **翻译灵活** - 可以根据文化偏好调整显示名称

**实现示例**:

**en.lproj/Localizable.strings**:
```
"language.system" = "System";
"language.english" = "English";
"language.chinese" = "Simplified Chinese";
```

**zh-Hans.lproj/Localizable.strings**:
```
"language.system" = "跟随系统";
"language.english" = "English";
"language.chinese" = "简体中文";
```

### 替代方案

| 方案 | 优点 | 缺点 | 是否采用 |
|------|------|------|----------|
| Locale.localizedString(forLanguageCode:) | 自动获取本地化名称 | 显示名称不符合规范澄清要求 | ❌ |
| 始终显示英文名称 | 实现简单 | 不符合本地化最佳实践 | ❌ |
| 始终显示母语名称 | 直观 | 在不同 UI 环境下显示一致，不符合本地化原则 | ❌ |

---

## 5. 数据持久化

### 决策：UserDefaults 存储 AppLanguage 枚举的 rawValue

**选择方案**: 将 `AppLanguage.rawValue` 存储到 UserDefaults

**理由**:
- **轻量快速** - 无需额外存储服务
- **符合现有模式** - 项目已使用 UserDefaults 存储用户设置
- **类型安全** - 枚举 rawValue 保证有效性

**实现**:
```swift
private enum Keys {
    static let appLanguage = "appLanguage"
}

// 保存
UserDefaults.standard.set(currentLanguage.rawValue, forKey: Keys.appLanguage)

// 加载
if let savedRaw = UserDefaults.standard.string(forKey: Keys.appLanguage),
   let saved = AppLanguage(rawValue: savedRaw) {
    currentLanguage = saved
}
```

---

## 6. 性能考虑

### 语言切换性能目标

| 指标 | 要求 | 实现方式 |
|------|------|----------|
| 切换响应时间 | < 500ms | @Published 自动通知 + SwiftUI 增量更新 |
| 应用启动语言初始化 | < 100ms | UserDefaults 读取 + 枚举转换 |
| 本地化字符串加载 | < 50ms | Bundle.main 内置缓存 |

### 优化策略

1. **延迟加载** - 只在需要时加载本地化字符串
2. **视图 ID 刷新** - 使用 `.id()` 强制刷新关键视图
3. **环境值传播** - 通过 `.environment(\.locale)` 自动传播到所有子视图

---

## 7. 与现有架构的集成

### MVVM + Service 架构对齐

| 组件 | 职责 |
|------|------|
| `LocalizationService` (Service) | 单例服务，管理当前语言状态，提供 locale |
| `AppLanguage` (Model) | 语言枚举，定义支持的语言类型 |
| `SettingsViewModel` (ViewModel) | 连接 LocalizationService 和设置 UI |
| `LanguageSettingsPanelView` (View) | 语言切换 UI 界面 |

### 通知机制

- **内部状态变化**: `@Published var currentLanguage` 自动触发视图更新
- **跨组件通信**: 不需要额外的 NotificationCenter，环境值自动传播

---

## 8. 未解决的 NEEDS CLARIFICATION

✅ **全部解决** - Technical Context 中所有待研究项已完成。

---

## 9. 技术风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 本地化字符串遗漏 | 部分 UI 仍显示原始语言 | 建立字符串清单，逐项检查 |
| 语言切换后视图未刷新 | 用户体验不一致 | 使用 `.id()` 强制刷新，确保环境值传播 |
| 系统语言检测不准确 | 新用户默认语言不符合预期 | 添加单元测试覆盖常见 locale |

---

## 10. 参考资料

### Apple 官方文档
- [Localizing Your App](https://developer.apple.com/documentation/xcode/localization) - Xcode 本地化完整指南
- [NSLocale.preferredLanguages](https://developer.apple.com/documentation/foundation/nslocale/1524244-preferredlanguages) - 系统语言偏好 API
- [Environment values in SwiftUI](https://developer.apple.com/documentation/swiftui/environment-values) - SwiftUI 环境值文档

### 社区资源
- [AppCoda: In-App Language Switch in SwiftUI](https://www.appcoda.com/swiftui-language-switch/) - 运行时语言切换教程
- [Swift by Sundell: Localization in SwiftUI](https://www.swiftbysundell.com/articles/localization-in-swiftui/) - SwiftUI 本地化最佳实践
- [Hacking with Swift: How to detect user language](https://www.hackingwithswift.com/example-code/system/how-to-detect-users-preferred-language) - 语言检测代码示例

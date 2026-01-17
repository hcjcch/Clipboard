# Quickstart: 多语言切换功能

**Feature**: 多语言切换功能
**Date**: 2025-01-17

## 快速开始指南

本指南帮助开发者快速理解多语言切换功能的实现方式，以便进行代码实现。

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                         App Layer                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  ClipboardApp (App Entry)                               ││
│  │  - 注入 LocalizationService 到环境                     ││
│  │  - 设置 .environment(\.locale)                          ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  SettingsWindow (Settings View)                         ││
│  │  - LanguageSettingsPanelView (新增)                    ││
│  │  - 语言下拉选择器                                       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  LocalizationService (单例)                             ││
│  │  - currentLanguage: AppLanguage (@Published)           ││
│  │  - setLanguage()                                        ││
│  │  - detectSystemLanguage()                               ││
│  │  - 持久化到 UserDefaults                                ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Storage Layer                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  UserDefaults                                           ││
│  │  Key: "appLanguage" → AppLanguage.rawValue             ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  .lproj Files                                           ││
│  │  - Resources/zh-Hans.lproj/Localizable.strings          ││
│  │  - Resources/en.lproj/Localizable.strings               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 实现步骤清单

### Step 1: 创建语言枚举

**文件**: `Clipboard/Models/AppLanguage.swift`

```swift
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }

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

### Step 2: 创建本地化服务

**文件**: `Clipboard/Services/LocalizationService.swift`

```swift
@MainActor
@Observable
final class LocalizationService {
    static let shared = LocalizationService()

    private(set) var currentLanguage: AppLanguage = .english {
        didSet { saveLanguage() }
    }

    var locale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier)
    }

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadSavedLanguage()
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    private func loadSavedLanguage() {
        if let saved = userDefaults.string(forKey: "appLanguage").flatMap(AppLanguage.init(rawValue:)) {
            currentLanguage = saved
        } else {
            currentLanguage = detectSystemLanguage()
        }
    }

    private func saveLanguage() {
        userDefaults.set(currentLanguage.rawValue, forKey: "appLanguage")
    }

    func detectSystemLanguage() -> AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
            ? .simplifiedChinese
            : .english
    }
}
```

### Step 3: 创建本地化资源文件

**文件**: `Clipboard/Resources/zh-Hans.lproj/Localizable.strings`

```
/* Language names */
"language.english" = "English";
"language.simplified_chinese" = "简体中文";

/* Settings */
"settings.language.title" = "语言";
"settings.language.description" = "选择应用界面的显示语言";
```

**文件**: `Clipboard/Resources/en.lproj/Localizable.strings`

```
/* Language names */
"language.english" = "English";
"language.simplified_chinese" = "Simplified Chinese";

/* Settings */
"settings.language.title" = "Language";
"settings.language.description" = "Choose the display language for the app";
```

### Step 4: 创建语言设置面板

**文件**: `Clipboard/Views/LanguageSettingsPanelView.swift`

```swift
struct LanguageSettingsPanelView: View {
    @Environment(LocalizationService.self) private var localizationService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.language.title")
                .font(.title2)

            Text("settings.language.description")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("", selection: Binding(
                get: { localizationService.currentLanguage },
                set: { localizationService.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
    }
}
```

### Step 5: 更新 SettingsOption

**文件**: `Clipboard/Models/SettingsOption.swift`

```swift
enum SettingsOption: String, CaseIterable, Identifiable {
    case hotkey
    case language  // 新增

    var displayName: String {
        switch self {
        case .hotkey: return "settings.hotkey"  // 改用本地化 key
        case .language: return "settings.language.title"
        }
    }

    var iconName: String {
        switch self {
        case .hotkey: return "keyboard"
        case .language: return "globe"  // 新增
        }
    }
}
```

### Step 6: 更新 SettingsView

**文件**: `Clipboard/Views/SettingsView.swift`

```swift
struct SettingsView: View {
    @State private var selectedOption: SettingsOption = .hotkey

    var body: some View {
        NavigationSplitView {
            SettingsSidebarView(selectedOption: $selectedOption)
        } detail: {
            switch selectedOption {
            case .hotkey:
                HotKeySettingsPanelView()
            case .language:
                LanguageSettingsPanelView()  // 新增
            }
        }
    }
}
```

### Step 7: 在 App 中注入 LocalizationService

**文件**: `Clipboard/ClipboardApp.swift`

```swift
@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var localizationService = LocalizationService.shared

    var body: some Scene {
        // ... 其他 scenes
        .environment(localizationService)
        .environment(\.locale, localizationService.locale)
    }
}
```

### Step 8: 更新 Package.swift

**文件**: `Package.swift`

```swift
sources: [
    // ... 现有文件
    "Models/AppLanguage.swift",           // 新增
    "Services/LocalizationService.swift", // 新增
    "Views/LanguageSettingsPanelView.swift", // 新增
    // ...
],
resources: [
    .process("Assets.xcassets"),
    // 添加本地化资源
    .copy("Resources/zh-Hans.lproj"),
    .copy("Resources/en.lproj"),
]
```

---

## 测试清单

### 功能测试

- [ ] 首次启动应用时，系统为中文则默认显示中文
- [ ] 首次启动应用时，系统为英文则默认显示英文
- [ ] 在设置页面切换语言后，所有界面文字立即更新
- [ ] 关闭并重新打开应用，语言设置保持不变
- [ ] 状态栏菜单的文字随语言切换更新

### 边缘案例测试

- [ ] 系统语言为繁体中文时，默认使用简体中文
- [ ] 系统语言为不支持的语言（如法语）时，默认使用英文
- [ ] 快速连续切换语言，应用响应正常
- [ ] 本地化资源文件缺失时，应用使用英文回退

---

## 故障排查

### 语言切换后视图未更新

**可能原因**: LocalizationService 未正确注入到环境

**解决方法**:
1. 确认 App 中有 `.environment(localizationService)`
2. 确认有 `.environment(\.locale, localizationService.locale)`
3. 检查视图是否使用了 `@Environment(LocalizationService.self)`

### 本地化字符串显示为 key

**可能原因**: Localizable.strings 文件未正确加载或 key 不存在

**解决方法**:
1. 确认 .lproj 目录在 Resources 下
2. 确认 Package.swift 包含 resources 配置
3. 检查 strings 文件格式（注意分号）
4. 运行 `swift build` 确认资源编译成功

### 系统语言检测不准确

**可能原因**: Locale.preferredLanguages 返回值不符合预期

**解决方法**:
1. 在 detectSystemLanguage() 中添加日志输出
2. 打印 Locale.preferredLanguages 查看实际值
3. 调整前缀匹配逻辑

---

## 性能考虑

- **语言切换响应**: < 500ms（通过 @Published 自动通知实现）
- **应用启动初始化**: < 100ms（UserDefaults 读取快速）
- **本地化字符串加载**: 懒加载，仅在首次使用时加载

---

## 扩展建议

如果未来需要支持更多语言：

1. 在 `AppLanguage` 枚举中添加新的 case
2. 创建对应的 `.lproj` 目录和 `Localizable.strings` 文件
3. 在 `detectSystemLanguage()` 中添加新的语言检测逻辑

示例：

```swift
enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"  // 新增

    // displayName 和其他属性自动扩展
}
```

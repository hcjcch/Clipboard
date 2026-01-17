# Implementation Plan: 多语言切换功能

**Branch**: `001-i18n-lang-switch` | **Date**: 2025-01-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-i18n-lang-switch/spec.md`

## Summary

实现支持中英文切换的多语言功能，允许用户在设置页面通过下拉菜单切换应用语言。功能包括：语言持久化存储、根据系统语言自动初始化、所有界面 UI 文字实时切换、状态栏菜单语言同步更新。使用 macOS 原生本地化框架（Foundation 的 NSLocalizedString/Locale）配合 SwiftUI 的本地化支持。

## Technical Context

**Language/Version**: Swift 6.0
**Primary Dependencies**: SwiftUI (UI), AppKit (NSPanel, NSStatusItem), Foundation (Localization, UserDefaults), Combine (Observable)
**Storage**: UserDefaults (语言设置), .lproj 文件 (本地化字符串资源), SQLite (剪贴板历史 - 不受语言切换影响)
**Testing**: 手动测试（语言切换功能主要通过 UI 交互验证）
**Target Platform**: macOS 15.0+
**Project Type**: Single project (macOS application)
**Performance Goals**: 语言切换响应 < 500ms, 应用启动时语言初始化 < 100ms
**Constraints**: 必须使用 MVVM + Service 架构, 语言切换不影响剪贴板历史数据, 所有 UI 文字必须可本地化
**Scale/Scope**: 2 种语言（简体中文、英文）, 约 50+ 个界面字符串需要本地化

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### 原则合规性评估

| 原则 | 状态 | 说明 |
|------|------|------|
| I. 用户体验至上 | ✅ PASS | 语言切换 < 500ms 符合性能要求; 切换立即生效无额外操作 |
| II. 原生平台集成 | ✅ PASS | 使用 Foundation 本地化框架 + SwiftUI 本地化支持; 完全符合 macOS 原生模式 |
| III. 架构清晰性 | ✅ PASS | 遵循 MVVM + Service: LocalizationService (单例) + AppLanguage 模型 + ViewModel 更新 |
| IV. 数据完整性 | ✅ PASS | 语言设置持久化到 UserDefaults; 剪贴板历史数据不受语言切换影响 |
| V. 搜索精确性 | N/A | 本功能不涉及搜索逻辑 |

### 技术栈约束检查

| 约束 | 状态 | 说明 |
|------|------|------|
| Swift 6.0 | ✅ PASS | 使用 Swift 6.0 语法和并发模型 |
| macOS 15.0+ | ✅ PASS | 本地化 API 在目标平台完全支持 |
| SwiftUI + AppKit | ✅ PASS | SwiftUI 视图 + AppKit 系统组件 |
| MVVM + Service | ✅ PASS | 新增 LocalizationService 遵循单例模式 |

### 性能约束检查

| 约束 | 要求 | 状态 |
|------|------|------|
| 语言切换响应 | < 500ms | ✅ PASS (FR-007) |
| 应用启动语言初始化 | < 100ms | ✅ PASS (UserDefaults 读取快速) |

**Gate Result**: ✅ **ALL PASSED** - 可以进入 Phase 0 研究

## Project Structure

### Documentation (this feature)

```text
specs/001-i18n-lang-switch/
├── plan.md              # 本文件
├── research.md          # Phase 0 输出
├── data-model.md        # Phase 1 输出
├── quickstart.md        # Phase 1 输出
└── contracts/           # Phase 1 输出 (本功能无 API contracts)
```

### Source Code (repository root)

```text
Clipboard/
├── Models/
│   ├── AppLanguage.swift           # 新增: 语言枚举 (简体中文/英文)
│   ├── UserSettings.swift           # 修改: 添加 selectedLanguage 字段
│   └── [existing models...]
├── Services/
│   ├── LocalizationService.swift    # 新增: 本地化服务 (单例)
│   ├── UserSettingsService.swift    # 修改: 添加语言设置的持久化
│   └── [existing services...]
├── ViewModels/
│   ├── SettingsViewModel.swift      # 修改: 添加语言切换状态管理
│   └── [existing viewmodels...]
├── Views/
│   ├── LanguageSettingsPanelView.swift  # 新增: 语言设置面板
│   ├── SettingsView.swift           # 修改: 添加语言设置选项
│   ├── SettingsSidebarView.swift    # 修改: 添加语言选项导航
│   ├── Models/SettingsOption.swift  # 修改: 添加 .language case
│   └── [existing views...]
├── Resources/                       # 新增目录
│   ├── zh-Hans.lproj/               # 简体中文本地化资源
│   │   └── Localizable.strings
│   └── en.lproj/                    # 英文本地化资源
│       └── Localizable.strings
└── Utils/
    └── [existing utils...]
```

**Structure Decision**: 单项目结构 (Option 1)。新增 `LocalizationService` 作为单例服务管理本地化逻辑，符合项目现有架构模式。本地化资源文件放在标准的 `.lproj` 目录中，遵循 macOS 本地化最佳实践。

## Complexity Tracking

> **本功能无需填写此表** - Constitution Check 全部通过，无违规需要justify。

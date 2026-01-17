# Tasks: 多语言切换功能

**Input**: Design documents from `/specs/001-i18n-lang-switch/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: 本功能使用手动测试验证，不包含自动化测试任务。

**Organization**: 任务按用户故事分组，确保每个故事可以独立实现和测试。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行（不同文件，无依赖）
- **[Story]**: 任务所属的用户故事（US1, US2, US3）
- 包含精确的文件路径

## Path Conventions

- **Single project**: macOS 应用使用 `Clipboard/` 作为源码根目录
- 资源文件: `Clipboard/Resources/`
- 本地化文件: `Clipboard/Resources/[locale].lproj/`

---

## Phase 1: Setup (共享基础设施)

**Purpose**: 项目初始化和基本结构设置

- [ ] T001 在 Clipboard/ 下创建 Resources 目录结构用于存放本地化资源
- [ ] T002 [P] 在 Clipboard/Resources/ 下创建 zh-Hans.lproj 目录（简体中文）
- [ ] T003 [P] 在 Clipboard/Resources/ 下创建 en.lproj 目录（英文）

---

## Phase 2: Foundational (阻塞前置条件)

**Purpose**: 所有用户故事依赖的核心基础设施

**⚠️ CRITICAL**: 在此阶段完成前，不能开始任何用户故事的实现

- [ ] T004 创建 AppLanguage 枚举在 Clipboard/Models/AppLanguage.swift，定义简体中文(simplifiedChinese)和英文(english)两个 case
- [ ] T005 在 AppLanguage 中实现 localeIdentifier 计算属性，返回对应的 locale 标识符
- [ ] T006 在 AppLanguage 中实现 displayName 计算属性，从 Localizable.strings 读取本地化语言名称
- [ ] T007 创建 LocalizationService 单例服务在 Clipboard/Services/LocalizationService.swift，使用 @MainActor 和 @Observable
- [ ] T008 在 LocalizationService 中实现 currentLanguage 属性（@Published），类型为 AppLanguage
- [ ] T009 在 LocalizationService 中实现 locale 计算属性，返回当前语言的 Locale 对象
- [ ] T010 在 LocalizationService 中实现 loadSavedLanguage() 私有方法，从 UserDefaults 读取保存的语言
- [ ] T011 在 LocalizationService 中实现 saveLanguage() 私有方法，将当前语言保存到 UserDefaults
- [ ] T012 在 LocalizationService 中实现 setLanguage(_:) 公开方法，设置应用语言
- [ ] T013 在 LocalizationService 中实现 detectSystemLanguage() 方法，检测系统语言并返回支持的 AppLanguage
- [ ] T014 在 Clipboard/ClipboardApp.swift 中注入 LocalizationService 到环境
- [ ] T015 在 Clipboard/ClipboardApp.swift 中设置 .environment(\.locale, localizationService.locale)

**Checkpoint**: 基础设施就绪 - 用户故事实现现在可以并行开始

---

## Phase 3: User Story 1 - 在设置页面切换语言 (Priority: P1) 🎯 MVP

**Goal**: 用户可以在设置页面通过下拉菜单切换应用语言，切换立即生效并持久化保存

**Independent Test**: 打开设置页面 → 选择语言 → 验证所有界面文字立即切换 → 重启应用验证语言设置保持不变

### Implementation for User Story 1

- [ ] T016 [P] 在 Clipboard/Resources/zh-Hans.lproj/ 下创建 Localizable.strings 文件
- [ ] T017 [P] 在 Clipboard/Resources/en.lproj/ 下创建 Localizable.strings 文件
- [ ] T018 [P] 在 zh-Hans.lproj/Localizable.strings 中添加语言名称 key: "language.english" = "English";
- [ ] T019 [P] 在 zh-Hans.lproj/Localizable.strings 中添加语言名称 key: "language.simplified_chinese" = "简体中文";
- [ ] T020 [P] 在 en.lproj/Localizable.strings 中添加语言名称 key: "language.english" = "English";
- [ ] T021 [P] 在 en.lproj/Localizable.strings 中添加语言名称 key: "language.simplified_chinese" = "Simplified Chinese";
- [ ] T022 [P] 在 zh-Hans.lproj/Localizable.strings 中添加设置页面相关 key（如 "settings.language.title" = "语言";）
- [ ] T023 [P] 在 en.lproj/Localizable.strings 中添加设置页面相关 key（如 "settings.language.title" = "Language";）
- [ ] T024 [US1] 创建 LanguageSettingsPanelView 在 Clipboard/Views/LanguageSettingsPanelView.swift
- [ ] T025 [US1] 在 LanguageSettingsPanelView 中注入 @Environment(LocalizationService.self)
- [ ] T026 [US1] 在 LanguageSettingsPanelView 中实现 Picker 视图，使用 .menu 样式（下拉菜单）
- [ ] T027 [US1] 在 LanguageSettingsPanelView 中为所有 AppLanguage.allCases 创建选项，使用 Text(language.displayName).tag(language)
- [ ] T028 [US1] 在 LanguageSettingsPanelView 中绑定 selection 到 $localizationService.currentLanguage
- [ ] T029 [P] [US1] 修改 Clipboard/Models/SettingsOption.swift，添加 .language case
- [ ] T030 [P] [US1] 在 SettingsOption.language 的 displayName 中返回本地化 key "settings.language.title"
- [ ] T031 [P] [US1] 在 SettingsOption.language 的 iconName 中返回 "globe"
- [ ] T032 [US1] 修改 Clipboard/Views/SettingsView.swift，在 detailContent switch 语句中添加 .language case
- [ ] T033 [US1] 在 .language case 中返回 LanguageSettingsPanelView()
- [ ] T034 [P] [US1] 更新 Package.swift，在 sources 中添加 "Models/AppLanguage.swift"
- [ ] T035 [P] [US1] 更新 Package.swift，在 sources 中添加 "Services/LocalizationService.swift"
- [ ] T036 [P] [US1] 更新 Package.swift，在 sources 中添加 "Views/LanguageSettingsPanelView.swift"
- [ ] T037 [P] [US1] 更新 Package.swift，在 resources 中添加 .copy("Resources/zh-Hans.lproj")
- [ ] T038 [P] [US1] 更新 Package.swift，在 resources 中添加 .copy("Resources/en.lproj")

**Checkpoint**: 此时 User Story 1 应该完全可用并可独立测试 - 用户可以在设置页面切换语言

---

## Phase 4: User Story 2 - 新用户首次使用时的默认语言 (Priority: P2)

**Goal**: 新用户首次启动应用时，根据系统语言自动选择默认界面语言

**Independent Test**: 更改系统语言为中文 → 全新安装应用 → 验证界面默认显示中文；更改为英文 → 验证默认显示英文

### Implementation for User Story 2

- [ ] T039 [US2] 在 LocalizationService 的 init 方法中调用 loadSavedLanguage() 而非直接设置默认值
- [ ] T040 [US2] 在 loadSavedLanguage() 中添加逻辑：如果 UserDefaults 中没有保存的语言，则调用 detectSystemLanguage()
- [ ] T041 [US2] 在 detectSystemLanguage() 中实现 Locale.preferredLanguages 检测逻辑
- [ ] T042 [US2] 在 detectSystemLanguage() 中添加前缀匹配：如果首选语言以 "zh" 开头，返回 .simplifiedChinese
- [ ] T043 [US2] 在 detectSystemLanguage() 中添加回退逻辑：其他所有语言返回 .english
- [ ] T044 [US2] 在 LocalizationService 中添加初始化日志，输出检测到的系统语言和最终设置的语言

**Checkpoint**: 此时 User Story 1 AND User Story 2 都应该独立工作 - 新用户自动获得合适的默认语言

---

## Phase 5: User Story 3 - 状态栏菜单的语言切换 (Priority: P3)

**Goal**: 状态栏菜单的选项和提示文字能够跟随应用语言设置进行切换

**Independent Test**: 切换应用语言 → 点击状态栏图标 → 验证菜单项文字正确显示为当前语言

### Implementation for User Story 3

- [ ] T045 [P] [US3] 在 zh-Hans.lproj/Localizable.strings 中添加状态栏菜单相关 key（如 "statusbar.quit" = "退出"; "statusbar.settings" = "设置";）
- [ ] T046 [P] [US3] 在 en.lproj/Localizable.strings 中添加状态栏菜单相关 key（如 "statusbar.quit" = "Quit"; "statusbar.settings" = "Settings";）
- [ ] T047 [US3] 修改 Clipboard/Services/StatusBarManager.swift，将菜单项文字从硬编码改为 String(localized:) 调用
- [ ] T048 [US3] 在 StatusBarManager 中确保菜单使用环境中的 locale，通过 LocalizationService.locale
- [ ] T049 [US3] 测试验证：切换语言后点击状态栏菜单，验证文字正确更新

**Checkpoint**: 所有用户故事现在都应该独立工作 - 状态栏菜单随语言切换更新

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 影响多个用户故事的改进和完善

- [ ] T050 [P] 将主窗口 ClipboardMainWindow 中的硬编码文字替换为本地化 key
- [ ] T051 [P] 将 ClipboardHistoryView 中的硬编码文字替换为本地化 key
- [ ] T052 [P] 将 ClipboardItemRowView 中的硬编码文字替换为本地化 key
- [ ] T053 [P] 将 SearchInputOverlay 中的硬编码文字替换为本地化 key
- [ ] T054 [P] 将 HotKeySettingsPanelView 中的硬编码文字替换为本地化 key
- [ ] T055 [P] 在 zh-Hans.lproj/Localizable.strings 中补充所有新增 key 的中文翻译
- [ ] T056 [P] 在 en.lproj/Localizable.strings 中补充所有新增 key 的英文翻译
- [ ] T057 验证所有界面文字在语言切换后正确更新
- [ ] T058 验证边缘案例：系统语言为繁体中文时默认使用简体中文
- [ ] T059 验证边缘案例：系统语言为不支持的语言（如法语）时默认使用英文
- [ ] T060 验证边缘案例：语言资源文件缺失时应用使用英文回退
- [ ] T061 运行 swift build 验证项目编译成功
- [ ] T062 手动测试：在设置页面切换语言，验证响应时间 < 500ms
- [ ] T063 手动测试：重启应用验证语言设置持久化保存
- [ ] T064 手动测试：验证状态栏菜单文字随语言切换更新

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖 - 可以立即开始
- **Foundational (Phase 2)**: 依赖 Setup 完成 - 阻塞所有用户故事
- **User Stories (Phase 3+)**: 都依赖 Foundational 阶段完成
  - 用户故事可以并行进行（如果有足够人力）
  - 或按优先级顺序执行（P1 → P2 → P3）
- **Polish (Phase 6)**: 依赖所有期望的用户故事完成

### User Story Dependencies

- **User Story 1 (P1)**: Foundational 完成后即可开始 - 不依赖其他故事
- **User Story 2 (P2)**: Foundational 完成后即可开始 - 不依赖 US1（系统语言检测是独立功能）
- **User Story 3 (P3)**: Foundational 完成后即可开始 - 不依赖 US1/US2（状态栏使用相同的 LocalizationService）

### Within Each User Story

- 本地化文件创建（[P]标记）可以并行执行
- 核心实现在依赖项完成后进行
- 用户故事完成后可以独立验证

### Parallel Opportunities

- Setup 阶段所有标记 [P] 的任务可以并行
- User Story 1: T016-T023（本地化文件创建）可以并行
- User Story 1: T029-T031（SettingsOption 修改）可以并行
- User Story 1: T034-T038（Package.swift 更新）应该串行（同一文件）
- User Story 3: T045-T046（本地化文件添加）可以并行
- Polish 阶段所有标记 [P] 的任务可以并行（不同文件）

---

## Parallel Example: User Story 1

```bash
# 并行启动所有本地化文件创建任务:
Task: "在 zh-Hans.lproj/Localizable.strings 中添加语言名称 key"
Task: "在 en.lproj/Localizable.strings 中添加语言名称 key"

# 并行启动 SettingsOption 相关任务:
Task: "修改 SettingsOption.swift，添加 .language case"
Task: "在 SettingsOption.language 的 displayName 中返回本地化 key"
Task: "在 SettingsOption.language 的 iconName 中返回 globe"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. 完成 Phase 1: Setup
2. 完成 Phase 2: Foundational (CRITICAL - 阻塞所有故事)
3. 完成 Phase 3: User Story 1
4. **停止并验证**: 独立测试 User Story 1
5. 准备好即可部署/演示

### Incremental Delivery

1. 完成 Setup + Foundational → 基础就绪
2. 添加 User Story 1 → 独立测试 → 部署/演示 (MVP!)
3. 添加 User Story 2 → 独立测试 → 部署/演示
4. 添加 User Story 3 → 独立测试 → 部署/演示
5. 每个故事增加价值而不破坏已有功能

### Single Developer Sequential

1. Phase 1 → Phase 2 → Phase 3 (US1) → 验证
2. Phase 4 (US2) → 验证
3. Phase 5 (US3) → 验证
4. Phase 6 (Polish) → 最终验证

---

## Notes

- [P] 任务 = 不同文件，无依赖，可并行
- [Story] 标签将任务映射到特定用户故事以便追踪
- 每个用户故事应该可以独立完成和测试
- 每个任务或逻辑组完成后提交代码
- 在任何检查点停止以独立验证故事
- 避免：模糊的任务、同一文件冲突、破坏独立性的跨故事依赖

---

## Task Summary

| Phase | Task Count | Description |
|-------|------------|-------------|
| Phase 1: Setup | 3 | 创建资源目录结构 |
| Phase 2: Foundational | 12 | 核心模型、服务和应用级配置 |
| Phase 3: User Story 1 (P1) | 23 | 设置页面语言切换 - MVP |
| Phase 4: User Story 2 (P2) | 6 | 系统语言检测 |
| Phase 5: User Story 3 (P3) | 5 | 状态栏菜单本地化 |
| Phase 6: Polish | 15 | 完整 UI 本地化和测试验证 |
| **Total** | **64** | |

### Parallel Opportunities

- **15 个任务**标记为 [P] 可并行执行
- **最大并行度**: Phase 3 可同时执行 8 个任务（T016-T023）
- **MVP 范围**: Phase 1 + Phase 2 + Phase 3 = 38 个任务

### Independent Test Criteria

| User Story | Test Criterion |
|------------|----------------|
| US1 | 设置页面切换语言 → 所有界面文字立即更新 → 重启验证持久化 |
| US2 | 修改系统语言 → 全新安装应用 → 验证默认语言正确 |
| US3 | 切换语言 → 点击状态栏 → 验证菜单文字正确更新 |

### Suggested MVP Scope

**MVP = Phase 1 + Phase 2 + Phase 3** (共 38 个任务)

这实现了核心功能：用户可以在设置页面切换语言，设置持久化保存，应用界面实时更新。

User Story 2 和 3 是增强体验的功能，可以在 MVP 后迭代添加。

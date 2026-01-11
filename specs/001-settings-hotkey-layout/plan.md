# Implementation Plan: 设置界面布局优化与快捷键自定义

**Branch**: `001-settings-hotkey-layout` | **Date**: 2026-01-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-settings-hotkey-layout/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

实现一个设置界面，允许用户自定义呼出剪贴板历史的全局快捷键。设置界面采用左右布局（左侧导航、右侧内容），通过状态栏图标访问。系统必须验证快捷键有效性，检测与 macOS 系统保留键的冲突，并支持立即应用更改。

## Technical Context

**Language/Version**: Swift 6.0
**Primary Dependencies**: SwiftUI (UI), AppKit (NSStatusItem, NSPanel), Carbon (全局快捷键注册)
**Storage**: UserDefaults (用户设置持久化)
**Testing**: 手动测试，关键逻辑添加日志
**Target Platform**: macOS 15.0+
**Project Type**: single - 单一 macOS 应用项目
**Performance Goals**:
- 设置界面打开响应: < 100ms
- 快捷键保存和应用: < 50ms
- 窗口切换动画: 60fps
**Constraints**:
- 状态栏图标必须始终可见
- 快捷键必须全局有效（任何应用中）
- 系统保留快捷键 100% 拦截率
**Scale/Scope**:
- 单一设置界面窗口
- 1 个设置选项（快捷键）
- 约 20 个系统保留快捷键需要检测

**技术决策** (来自 Phase 0 研究):
- 测试: 不添加 XCTest，通过手动测试验证
- 存储: 使用 UserDefaults + @AppStorage 属性包装器
- 布局: NavigationSplitView 实现左右布局
- 快捷键录制: 自定义 SwiftUI 视图 + NSEvent 监控
- 系统保留键: 静态列表，集合查找

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### 原则合规性检查

| 原则 | 状态 | 说明 |
|------|------|------|
| I. 用户体验至上 | ✅ PASS | 设置界面响应 < 100ms，快捷键立即生效 |
| II. 原生平台集成 | ✅ PASS | 使用 SwiftUI + AppKit + Carbon，符合要求 |
| III. 架构清晰性 | ✅ PASS | 遵循 MVVM + Service 架构，无违规 |
| IV. 数据完整性 | ✅ PASS | 使用 UserDefaults 持久化，符合要求 |
| V. 搜索精确性 | ⚠ N/A | 此功能不涉及搜索 |

### Phase 0 研究后重新评估

所有技术决策已通过研究确定，无原则违规。

### Phase 1 设计后重新评估

数据模型设计遵循架构清晰性原则：
- Models 层：UserSettings、HotKeyDefinition 纯数据结构
- ViewModels 层：SettingsViewModel 处理 UI 状态
- Services 层：UserSettingsService 单例，封装持久化逻辑
- Views 层：HotKeyRecorderView、SettingsSidebarView 只负责渲染

**最终结论**: 所有原则合规，设计阶段完成，可以进入任务分解阶段（/speckit.tasks）。

## Project Structure

### Documentation (this feature)

```text
specs/001-settings-hotkey-layout/
├── spec.md              # 功能规格说明
├── plan.md              # 本文件 (实现计划)
├── research.md          # Phase 0 输出 (技术研究)
├── data-model.md        # Phase 1 输出 (数据模型)
├── quickstart.md        # Phase 1 输出 (快速开始指南)
├── contracts/           # Phase 1 输出 (API 契约 - 本功能不适用)
├── checklists/          # 质量检查清单
│   └── requirements.md  # 规格质量验证
└── tasks.md             # Phase 2 输出 (任务列表 - 由 /speckit.tasks 生成)
```

### Source Code (repository root)

```text
Clipboard/
├── Models/                          # 数据模型（纯数据结构）
│   ├── ClipboardItem.swift         # 现有
│   ├── ClipboardItemType.swift     # 现有
│   ├── MatchResult.swift           # 现有
│   ├── UserSettings.swift          # 新增 - 用户设置数据模型
│   └── HotKeyDefinition.swift      # 新增 - 快捷键定义模型
│
├── ViewModels/                      # 视图模型（@Observable, 状态管理）
│   ├── ClipboardItemViewModel.swift # 现有
│   ├── ClipboardHistoryViewModel.swift # 现有
│   └── SettingsViewModel.swift     # 新增 - 设置界面视图模型
│
├── Views/                           # SwiftUI 视图组件
│   ├── ClipboardMainWindow.swift   # 现有
│   ├── ClipboardHistoryView.swift  # 现有
│   ├── ClipboardItemRowView.swift  # 现有
│   ├── DesignSystem.swift          # 现有
│   ├── HiddenInputField.swift      # 现有
│   ├── SearchInputOverlay.swift    # 现有
│   ├── SettingsView.swift          # 现有 - 需要重写为左右布局
│   ├── SettingsWindowManager.swift # 现有 - 需要增强
│   ├── HotKeyRecorderView.swift    # 新增 - 快捷键录制控件
│   └── SettingsSidebarView.swift   # 新增 - 设置界面左侧导航
│
├── Services/                        # 业务逻辑服务（单例 .shared）
│   ├── DatabaseService.swift       # 现有
│   ├── ClipboardMonitorService.swift # 现有
│   ├── HotKeyManager.swift         # 现有 - 需要增强（支持自定义快捷键）
│   ├── ImageStorageService.swift   # 现有
│   ├── StatusBarManager.swift      # 现有 - 需要增强（添加"设置"菜单项）
│   └── UserSettingsService.swift   # 新增 - 用户设置持久化服务
│
└── Utils/                           # 工具类和算法
    ├── FuzzyMatcher.swift          # 现有
    ├── TextHighlighter.swift       # 现有
    └── SystemHotKeyValidator.swift # 新增 - 系统保留快捷键验证器
```

**Structure Decision**: 单一 macOS 应用项目，采用标准的 MVVM + Service 分层架构。新增文件遵循现有命名约定和目录结构。

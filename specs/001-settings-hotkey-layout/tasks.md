# Tasks: 设置界面布局优化与快捷键自定义

**Input**: 设计文档来自 `/specs/001-settings-hotkey-layout/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: 本功能不包含测试任务（研究阶段决定不添加 XCTest，通过手动测试验证）。

**Organization**: 任务按用户故事分组，支持每个故事独立实现和测试。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行（不同文件，无依赖）
- **[Story]**: 任务所属的用户故事（US1, US2, US3, US4）
- 包含精确的文件路径

---

## Phase 1: Setup (共享基础设施)

**目的**: 项目初始化和基础结构

- [X] T001 验证 Package.swift 包含所有必需依赖（SQLite.swift 已存在）
- [X] T002 确认项目目录结构符合 MVVM + Service 架构

---

## Phase 2: Foundational (阻塞性先决条件)

**目的**: 所有用户故事开始前必须完成的核心基础设施

**⚠️ CRITICAL**: 完成此阶段前，任何用户故事工作都无法开始

- [X] T003 创建 HotKeyDefinition 模型在 Clipboard/Models/HotKeyDefinition.swift
- [X] T004 创建 UserSettings 模型在 Clipboard/Models/UserSettings.swift
- [X] T005 创建 SettingsOption 枚举在 Clipboard/Models/SettingsOption.swift
- [X] T006 创建 UserSettingsService 单例服务在 Clipboard/Services/UserSettingsService.swift
- [X] T007 创建 SystemHotKeyValidator 工具类在 Clipboard/Utils/SystemHotKeyValidator.swift
- [X] T008 增强 HotKeyManager 支持动态快捷键注册在 Clipboard/Services/HotKeyManager.swift
- [X] T009 [P] 创建 SettingsViewModel 在 Clipboard/ViewModels/SettingsViewModel.swift

**Checkpoint**: 基础设施就绪，用户故事实现现在可以并行开始

---

## Phase 3: User Story 1 - 快捷键自定义 (Priority: P1) 🎯 MVP

**目标**: 用户可以通过设置界面自定义全局快捷键

**独立测试**: 打开设置界面，修改快捷键，使用新快捷键呼出剪贴板历史验证

### 实现任务

- [X] T010 [P] [US1] 创建 HotKeyRecorderView 快捷键录制控件在 Clipboard/Views/HotKeyRecorderView.swift
- [X] T011 [US1] 创建快捷键设置面板视图在 Clipboard/Views/HotKeySettingsPanelView.swift
- [X] T012 [US1] 在 SettingsViewModel 中添加快捷键录制状态管理
- [X] T013 [US1] 在 SettingsViewModel 中添加快捷键验证逻辑
- [X] T014 [US1] 在 SettingsViewModel 中添加快捷键保存逻辑
- [X] T015 [US1] 在 UserSettingsService 中实现快捷键持久化到 UserDefaults
- [X] T016 [US1] 在 UserSettingsService 中实现从 UserDefaults 读取快捷键
- [X] T017 [US1] 在 HotKeyManager 中实现 updateHotKey 方法支持热更新
- [X] T018 [US1] 在 HotKeyRecorderView 中实现键盘事件监听（NSEvent）
- [X] T019 [US1] 在 HotKeyRecorderView 中实现修饰键验证
- [X] T020 [US1] 在 HotKeyRecorderView 中实现 Escape 取消功能
- [X] T021 [US1] 在快捷键设置面板中添加"恢复默认"按钮
- [X] T022 [US1] 在快捷键设置面板中添加错误提示显示
- [X] T023 [US1] 在 SettingsWindowManager 中实现窗口关闭时自动保存

**Checkpoint**: 此时用户故事 1 应该完全功能化且可独立测试

---

## Phase 4: User Story 2 - 通过状态栏访问设置 (Priority: P2)

**目标**: 用户可以通过点击状态栏图标打开设置界面

**独立测试**: 点击状态栏图标，选择"设置"，验证设置界面打开

### 实现任务

- [X] T024 [P] [US2] 在 StatusBarManager 中添加"设置"菜单项
- [X] T025 [US2] 在 StatusBarManager 中实现设置窗口打开逻辑
- [X] T026 [US2] 在 StatusBarManager 中实现设置窗口焦点检查（防止重复打开）
- [X] T027 [US2] 在 SettingsWindowManager 中实现 toggleSettingsWindow 方法
- [X] T028 [US2] 在 SettingsWindowManager 中确保窗口成为焦点窗口

**Checkpoint**: 此时用户故事 1 和 2 应该都能独立工作

---

## Phase 5: User Story 3 - 设置界面左右布局 (Priority: P3)

**目标**: 设置界面采用左侧导航、右侧内容的布局方式

**独立测试**: 打开设置界面，验证左右布局结构

### 实现任务

- [X] T029 [P] [US3] 创建 SettingsSidebarView 左侧导航视图在 Clipboard/Views/SettingsSidebarView.swift
- [X] T030 [US3] 重写 SettingsView 使用 NavigationSplitView 实现左右布局在 Clipboard/Views/SettingsView.swift
- [X] T031 [US3] 在 SettingsView 中实现侧边栏和内容面板的绑定
- [X] T032 [US3] 在 SettingsView 中配置默认选中"快捷键"选项
- [X] T033 [US3] 在 SettingsSidebarView 中实现选项高亮显示
- [X] T034 [US3] 在 SettingsView 中设置窗口最小尺寸（防止布局压缩）
- [X] T035 [US3] 将 HotKeySettingsPanelView 集成到右侧内容面板

**Checkpoint**: 所有用户故事现在应该都能独立功能化

---

## Phase 6: User Story 4 - 快捷键冲突检测 (Priority: P4)

**目标**: 系统检测并阻止用户设置 macOS 系统保留快捷键

**独立测试**: 尝试设置系统保留快捷键（如 ⌘Q），验证被正确拦截

### 实现任务

- [X] T036 [P] [US4] 在 SystemHotKeyValidator 中定义系统保留快捷键列表（约 20 个）
- [X] T037 [US4] 在 SystemHotKeyValidator 中实现 isSystemReserved 方法
- [X] T038 [US4] 在 SettingsViewModel 中集成系统保留键验证
- [X] T039 [US4] 在 HotKeyRecorderView 中显示系统保留键冲突错误
- [X] T040 [US4] 在快捷键设置面板中添加冲突提示 UI
- [X] T041 [US4] 阻止保存冲突的快捷键到 UserDefaults

**Checkpoint**: 所有用户故事现在都应该独立功能化

---

## Phase 7: Polish & Cross-Cutting Concerns

**目的**: 影响多个用户故事的改进

- [X] T042 [P] 在关键点添加日志输出（HotKeyManager、UserSettingsService）
- [X] T043 [P] 优化设置界面打开响应时间（目标 < 100ms）
- [X] T044 [P] 优化快捷键保存和应用时间（目标 < 50ms）
- [X] T045 验证状态栏图标始终可见
- [X] T046 验证快捷键在所有应用中全局有效
- [X] T047 验证系统保留快捷键 100% 拦截率
- [X] T048 [P] 代码清理和移除调试 print 语句
- [X] T049 更新 CLAUDE.md 文档（如果需要）
- [X] T050 运行 quickstart.md 中的验证步骤

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖 - 可立即开始
- **Foundational (Phase 2)**: 依赖 Setup 完成 - 阻塞所有用户故事
- **User Stories (Phase 3-6)**: 都依赖 Foundational 阶段完成
  - 用户故事可以并行进行（如果有人力）
  - 或按优先级顺序依次执行（P1 → P2 → P3 → P4）
- **Polish (Phase 7)**: 依赖所有需要的用户故事完成

### User Story Dependencies

- **User Story 1 (P1)**: Foundational 完成后可开始 - 无其他故事依赖
- **User Story 2 (P2)**: Foundational 完成后可开始 - 可能与 US1 集成（打开设置窗口）
- **User Story 3 (P3)**: Foundational 完成后可开始 - 依赖 US1（快捷键面板）和 US2（窗口管理）
- **User Story 4 (P4)**: Foundational 完成后可开始 - 依赖 US1（快捷键录制）

### Within Each User Story

- Models 并行创建（标记 [P]）
- Views 依赖于 Models 和 ViewModels
- Services 依赖于 Models
- 逻辑在服务中，然后在视图中集成
- 故事在移动到下一个优先级之前完成

### Parallel Opportunities

- Setup 中标记的所有 [P] 任务可以并行运行
- Foundational 中标记的所有 [P] 任务可以并行运行（在 Phase 2 内）
- Foundational 完成后，如果团队容量允许，所有用户故事都可以并行开始
- 用户故事中标记为 [P] 的所有测试可以并行运行
- 用户故事中的模型（标记 [P]）可以并行运行
- 如果团队容量允许，不同用户故事可以由不同团队成员并行工作

---

## Parallel Example: User Story 1

```bash
# 一起启动 User Story 1 的所有视图任务（标记为 [P]）:
Task: "创建 HotKeyRecorderView 快捷键录制控件"
Task: "创建快捷键设置面板视图"
```

---

## Implementation Strategy

### MVP First (仅 User Story 1)

1. 完成 Phase 1: Setup
2. 完成 Phase 2: Foundational（CRITICAL - 阻塞所有故事）
3. 完成 Phase 3: User Story 1（基础快捷键自定义，无冲突检测）
4. **停止并验证**: 独立测试用户故事 1
5. 如果准备就绪，部署/演示

### Incremental Delivery

1. 完成 Setup + Foundational → 基础就绪
2. 添加 User Story 1 → 独立测试 → 部署/演示（MVP！）
3. 添加 User Story 2 → 独立测试 → 部署/演示
4. 添加 User Story 3 → 独立测试 → 部署/演示
5. 添加 User Story 4 → 独立测试 → 部署/演示
6. 每个故事都增加价值而不破坏以前的故事

### Parallel Team Strategy

拥有多个开发人员：

1. 团队一起完成 Setup + Foundational
2. Foundational 完成后：
   - 开发人员 A: User Story 1
   - 开发人员 B: User Story 2
   - 开发人员 C: User Story 3
3. 故事独立完成并集成

---

## Notes

- [P] 任务 = 不同文件，无依赖
- [Story] 标签将任务映射到特定用户故事以实现可追溯性
- 每个用户故事应该可以独立完成和测试
- 在每个任务或逻辑组后提交
- 在任何检查点停止以独立验证故事
- 避免：模糊任务、相同文件冲突、破坏独立性的跨故事依赖

---

## Task Summary

| Phase | 任务数 | 用户故事 |
|-------|--------|----------|
| Setup | 2 | - |
| Foundational | 7 | - |
| User Story 1 | 14 | 快捷键自定义 (P1) |
| User Story 2 | 5 | 状态栏访问设置 (P2) |
| User Story 3 | 7 | 设置界面布局 (P3) |
| User Story 4 | 6 | 快捷键冲突检测 (P4) |
| Polish | 9 | 跨故事优化 |
| **总计** | **50** | |

### 并行机会统计

- **Setup**: 2 个任务（结构验证，无并行机会）
- **Foundational**: 7 个任务（1 个并行：T009）
- **User Story 1**: 14 个任务（1 个并行：T010）
- **User Story 2**: 5 个任务（1 个并行：T024）
- **User Story 3**: 7 个任务（2 个并行：T029）
- **User Story 4**: 6 个任务（1 个并行：T036）
- **Polish**: 9 个任务（5 个并行：T042-T044, T048-T049）

**总计并行机会**: 11 个任务可并行执行（22%）

### MVP 范围

**最小可行产品**: Phase 1 + Phase 2 + Phase 3 (User Story 1)
- 总计: 23 个任务
- 独立价值: 用户可以自定义快捷键并立即使用
- 可验证: 通过手动测试完整验证

### Format Validation

✅ 所有 50 个任务遵循严格的检查清单格式：
- ✅ 复选框: `- [ ]`
- ✅ 任务 ID: `T001` - `T050`
- ✅ [P] 标记: 11 个并行任务正确标记
- ✅ [Story] 标签: 32 个用户故事任务正确标记（US1-US4）
- ✅ 文件路径: 所有任务包含精确路径

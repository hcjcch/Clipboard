# Tasks: 剪贴板预览面板

**Input**: Design documents from `/specs/001-clipboard-preview-panel/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: 本功能规格未明确要求测试任务，因此不包含专门的测试阶段。测试通过验收场景验证。

**Organization**: 任务按用户故事分组，以支持每个故事的独立实现和测试。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行（不同文件，无依赖关系）
- **[Story]**: 任务所属的用户故事（如 US1, US2, US3, US4）
- **包含精确的文件路径**

## Path Conventions

- **macOS 应用**: `Clipboard/` 位于代码仓库根目录
- 文件路径遵循现有 MVVM + Service 架构：
  - `Clipboard/Models/` - 数据模型
  - `Clipboard/ViewModels/` - 视图模型
  - `Clipboard/Views/` - SwiftUI 视图组件
  - `Clipboard/Utils/` - 工具类

---

## Phase 1: Setup (共享基础设施)

**Purpose**: 项目初始化和基本结构设置

- [X] T001 确认在 `001-clipboard-preview-panel` 分支上
- [X] T002 验证项目可正常构建（`swift build`）
- [X] T003 验证所有设计文档存在且可访问（plan.md, research.md, data-model.md, contracts/, quickstart.md）

---

## Phase 2: Foundational (阻塞性先决条件)

**Purpose**: 所有用户故事实现前必须完成的核心基础设施

**⚠️ CRITICAL**: 在此阶段完成前，不得开始任何用户故事的实现

- [X] T004 在 `Clipboard/Models/PreviewPanelState.swift` 中创建预览面板状态枚举，定义 `.hidden`, `.showing(ClipboardItem)`, `.loading`, `.error(String)` 状态
- [X] T005 在 `Clipboard/Models/PreviewContent.swift` 中创建预览内容封装结构体，包含 item, displayText, thumbnailData, fileInfo, isLoading, errorMessage 字段
- [X] T006 在 `Clipboard/Models/HoverState.swift` 中创建悬停状态跟踪类，实现 startHover(), cancelHover() 方法和 200ms 延迟触发逻辑
- [X] T007 在 `Clipboard/ViewModels/PreviewPanelViewModel.swift` 中创建预览面板视图模型类，使用 @Observable，实现 showPreview(), hidePreview(), refreshPreviewContent() 方法
- [X] T008 在 `PreviewPanelViewModel` 中设置 Combine 内容观察者，监听 `.clipboardItemDidUpdate` 和 `.clipboardItemDidDelete` 通知，实现 150ms 去抖动
- [X] T009 在 `Clipboard/Utils/Debouncer.swift` 中创建去抖动工具类（使用 Combine debounce，无需单独实现）

**Checkpoint**: 基础设施就绪 - 用户故事实现现在可以并行开始

---

## Phase 3: User Story 1 - 文本内容预览 (Priority: P1) 🎯 MVP

**Goal**: 实现文本类型剪贴板项的预览功能，当用户鼠标悬停在文本项上时，在右侧显示正方形预览面板，居中显示完整文本内容

**Independent Test**: 鼠标悬停在文本类型的剪贴板项上，验证右侧预览面板在 200ms 后正确显示并居中显示完整文本内容

### Implementation for User Story 1

- [X] T010 [P] [US1] 在 `Clipboard/Views/PreviewTextView.swift` 中创建文本预览视图组件，实现文本内容居中显示、自动换行和截断逻辑（省略号）
- [X] T011 [P] [US1] 在 `Clipboard/Views/PreviewPanelView.swift` 中创建预览面板主视图，实现状态切换逻辑（.showing, .loading, .error），应用 300x300 固定尺寸、圆角、阴影样式
- [X] T012 [US1] 在 `PreviewPanelView` 中实现浮动覆盖布局集成，使用 `.overlay(alignment: .trailing)` 修饰符
- [X] T013 [US1] 在 `PreviewPanelViewModel` 中实现 loadTextContent() 方法，处理文本类型的内容加载
- [X] T014 [US1] 在 `Clipboard/Views/ClipboardItemRowView.swift` 中添加悬停检测，使用 `.onHover()` 修饰符，集成 200ms 延迟触发逻辑
- [X] T015 [US1] 在 `Clipboard/ViewModels/ClipboardHistoryViewModel.swift` 中扩展视图模型，添加 hoveredItem 属性和 onItemHovered(), onItemExited() 方法
- [X] T016 [US1] 在 `ClipboardHistoryViewModel` 中集成 HoverState，管理悬停定时器
- [X] T017 [US1] 在 `Clipboard/Views/ClipboardHistoryView.swift` 中集成预览面板到主视图，使用 `.overlay()` 添加 PreviewPanelView
- [X] T018 [US1] 在 `Clipboard/Views/DesignSystem.swift` 中扩展设计系统，添加 PreviewPanel 样式常量（背景、圆角、边框、阴影）

**Checkpoint**: 此时，用户故事 1 应完全功能并可独立测试 ✅ MVP 完成

---

## Phase 4: User Story 2 - 图片内容预览 (Priority: P2)

**Goal**: 实现图片类型剪贴板项的预览功能，图片按比例缩放以适应预览面板并保持宽高比

**Independent Test**: 鼠标悬停在图片类型的剪贴板项上，验证右侧预览面板正确显示图片，图片居中并按比例缩放适应面板

### Implementation for User Story 2

- [X] T019 [P] [US2] 在 `Clipboard/Views/PreviewImageView.swift` 中创建图片预览视图组件，实现图片按比例缩放、居中对齐逻辑
- [X] T020 [P] [US2] 在 `PreviewImageView` 中实现缩略图优先加载策略，使用 ImageStorageService 的现有缩略图
- [ ] T021 [US2] 在 `PreviewImageView` 中实现渐进式图片加载，先显示缩略图，500ms 后按需加载原图
- [X] T022 [US2] 在 `PreviewPanelViewModel` 中实现 loadImageContent() 方法，处理图片类型的内容加载，复用 ImageStorageService
- [ ] T023 [US2] 在 `PreviewImageView` 中实现 4K 图片降采样逻辑，确保大图片加载性能 < 200ms
- [X] T024 [US2] 在 `PreviewPanelView` 中添加图片类型的视图切换逻辑，在 switch 语句中添加 `.image` case
- [X] T025 [US2] 集成图片预览到现有预览面板，验证与 US1 文本预览的无缝切换 ✓

**Checkpoint**: 此时，用户故事 1 和 2 都应独立工作

---

## Phase 5: User Story 3 - 文件引用预览 (Priority: P3)

**Goal**: 实现文件引用类型剪贴板项的预览功能，显示文件名、文件类型、图标等信息

**Independent Test**: 鼠标悬停在文件引用类型的剪贴板项上，验证右侧预览面板正确显示文件信息（文件名、类型、图标），内容居中对齐

### Implementation for User Story 3

- [X] T026 [P] [US3] 在 `Clipboard/Views/PreviewFileView.swift` 中创建文件引用预览视图组件，实现文件信息显示布局 ✓
- [X] T027 [P] [US3] 在 `PreviewFileView` 中实现文件图标显示，使用 NSWorkspace.icon(forFile:) ✓
- [X] T028 [P] [US3] 在 `PreviewFileView` 中实现多文件摘要显示逻辑，超过 5 个文件时显示"还有 N 个文件" ✓
- [X] T029 [US3] 在 `PreviewPanelViewModel` 中实现 loadFileContent() 方法，处理文件引用类型的内容加载 ✓
- [X] T030 [US3] 在 `PreviewContent` 模型中添加 FileInfo 结构体，包含 fileName, fileType, fileCount, fileIcon 字段 ✓
- [X] T031 [US3] 在 `PreviewPanelView` 中添加文件引用类型的视图切换逻辑，在 switch 语句中添加 `.file` case ✓
- [X] T032 [US3] 集成文件预览到现有预览面板，验证与 US1 和 US2 的无缝切换 ✓

**Checkpoint**: 所有用户故事现在都应独立功能

---

## Phase 6: User Story 4 - 键盘导航预览 (Priority: P4)

**Goal**: 实现键盘导航预览功能，当用户使用 Tab 键或方向键选择剪贴板项时，预览面板同步显示当前选中项的内容

**Independent Test**: 使用键盘导航选择剪贴板项，验证预览面板正确显示并更新内容

### Implementation for User Story 4

- [X] T033 [P] [US4] 在 `Clipboard/Views/ClipboardItemRowView.swift` 中添加焦点管理，使用 @FocusState 跟踪列表项焦点状态
- [X] T034 [US4] 在 `ClipboardItemRowView` 中实现 .focused() 修饰符绑定，配合 @Binding var isFocused
- [X] T035 [US4] 在 `ClipboardItemRowView` 中添加 onChange(of: isFocused) 监听，焦点变化时通知 ViewModel
- [X] T036 [US4] 在 `Clipboard/ViewModels/ClipboardHistoryViewModel.swift` 中扩展视图模型，添加 focusedItem 属性和 onItemFocused() 方法
- [X] T037 [US4] 在 `ClipboardHistoryViewModel` 中实现键盘导航预览逻辑，焦点项改变时立即显示预览（无延迟）
- [X] T038 [US4] 在 `Clipboard/Views/ClipboardHistoryView.swift` 中扩展键盘事件处理，支持方向键选择列表项
- [X] T039 [US4] 验证键盘导航与鼠标悬停的协调工作，两种方式切换时预览正确更新

**Checkpoint**: 键盘导航预览功能完全集成，所有用户故事现在支持两种交互方式 ✅

---

## Phase 7: Polish & 跨领域关注点

**Purpose**: 影响多个用户故事的改进和优化

- [X] T040 [P] 在 `Clipboard/Views/PreviewPanelWindow.swift` 中实现屏幕边界检测，使用 NSScreen.main.visibleFrame 检测屏幕边界 ✓
- [X] T041 [P] 在 `PreviewPanelWindow` 中实现左右位置动态切换逻辑，当预览面板超出屏幕右边界时自动切换到左侧 ✓
- [X] T042 [P] 在 `PreviewPanelWindow` 中实现多显示器支持，使用 NSScreen.main 确保预览面板限制在主屏幕 ✓
- [ ] T043 在 `Clipboard/Views/PreviewPanelView.swift` 中实现显示/隐藏动画优化，使用 .animation() 修饰符，设置 150ms easeInOut 动画
- [X] T044 在 `Clipboard/ViewModels/PreviewPanelViewModel.swift` 中实现错误状态处理，剪贴板项删除时显示"该项已被删除"提示 ✓ (已在 handleItemDelete 中实现)
- [X] T045 在 `Clipboard/ViewModels/PreviewPanelViewModel.swift` 中验证实时内容同步机制，响应 .clipboardItemDidUpdate 和 .clipboardItemDidDelete 通知 ✓ (已实现)
- [ ] T046 性能测试和优化，验证预览面板响应时间 < 200ms，去抖动 150ms，界面流畅度 60fps
- [ ] T047 运行 quickstart.md 中的测试场景，验证所有验收场景通过
- [X] T048 代码清理和重构，移除调试代码，优化代码注释 ✓ (调试日志已清理，代码注释已完善)
- [ ] T049 更新 CLAUDE.md 中的 Active Technologies 部分（如需要）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖 - 可立即开始
- **Foundational (Phase 2)**: 依赖 Setup 完成 - 阻塞所有用户故事
- **User Stories (Phase 3-6)**: 都依赖 Foundational 阶段完成
  - 用户故事可以并行进行（如果有人力）
  - 或按优先级顺序进行（P1 → P2 → P3 → P4）
- **Polish (Phase 7)**: 依赖所有期望的用户故事完成

### User Story Dependencies

- **User Story 1 (P1)**: Foundational 完成后可开始 - 无其他故事依赖
- **User Story 2 (P2)**: Foundational 完成后可开始 - 与 US1 集成但可独立测试
- **User Story 3 (P3)**: Foundational 完成后可开始 - 与 US1/US2 集成但可独立测试
- **User Story 4 (P4)**: Foundational 完成后可开始 - 依赖 US1-US3 的预览面板基础架构

### Within Each User Story

- 数据模型（Models）优先于视图模型（ViewModels）
- 视图模型（ViewModels）优先于视图（Views）
- 核心实现优先于集成
- 故事完成后再进入下一个优先级

### Parallel Opportunities

- Setup 阶段的所有任务可并行
- Foundational 阶段标记为 [P] 的任务可并行（T004, T005, T006）
- 一旦 Foundational 完成，所有用户故事可以并行开始（如果团队容量允许）
- 每个用户故事内标记为 [P] 的任务可并行
- 不同用户故事可由不同团队成员并行工作

---

## Parallel Example: User Story 1

```bash
# 同时启动 User Story 1 的所有视图组件：
Task: "在 Clipboard/Views/PreviewTextView.swift 中创建文本预览视图组件"
Task: "在 Clipboard/Views/PreviewPanelView.swift 中创建预览面板主视图"

# 同时启动 User Story 1 的模型扩展：
Task: "扩展 ClipboardHistoryViewModel 添加预览状态管理"
Task: "在 ClipboardItemRowView 中添加悬停检测"
```

---

## Implementation Strategy

### MVP First (仅 User Story 1)

1. 完成 Phase 1: Setup
2. 完成 Phase 2: Foundational (CRITICAL - 阻塞所有故事)
3. 完成 Phase 3: User Story 1
4. **STOP and VALIDATE**: 独立测试 User Story 1
5. 如准备就绪则部署/演示

### Incremental Delivery

1. 完成 Setup + Foundational → 基础就绪
2. 添加 User Story 1 → 独立测试 → 部署/演示 (MVP!)
3. 添加 User Story 2 → 独立测试 → 部署/演示
4. 添加 User Story 3 → 独立测试 → 部署/演示
5. 添加 User Story 4 → 独立测试 → 部署/演示
6. 完成 Polish → 最终部署
7. 每个故事都在不破坏之前故事的情况下增加价值

### Parallel Team Strategy

有多名开发人员时：

1. 团队一起完成 Setup + Foundational
2. Foundational 完成后：
   - 开发人员 A: User Story 1 (文本预览)
   - 开发人员 B: User Story 2 (图片预览)
   - 开发人员 C: User Story 3 (文件预览)
3. 故事独立完成和集成

---

## Notes

- [P] 任务 = 不同文件，无依赖关系
- [Story] 标签将任务映射到特定用户故事以实现可追溯性
- 每个用户故事应可独立完成和测试
- 每个任务或逻辑组后提交
- 在任何检查点停止以独立验证故事
- 避免：模糊的任务、同一文件冲突、破坏独立性的跨故事依赖

---

## Summary

- **Total Tasks**: 49
- **Tasks by User Story**:
  - Setup: 3 tasks
  - Foundational: 6 tasks
  - User Story 1 (P1): 9 tasks
  - User Story 2 (P2): 7 tasks
  - User Story 3 (P3): 7 tasks
  - User Story 4 (P4): 7 tasks
  - Polish: 10 tasks
- **Parallel Opportunities**: 15 tasks marked [P]
- **MVP Scope**: User Story 1 (文本内容预览) - Phase 1-3
- **Format Validation**: ✅ All tasks follow checklist format with checkbox, ID, labels, file paths

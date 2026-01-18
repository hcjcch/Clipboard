# Implementation Plan: 剪贴板预览面板

**Branch**: `001-clipboard-preview-panel` | **Date**: 2025-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-clipboard-preview-panel/spec.md`

## Summary

为剪贴板历史管理应用添加预览面板功能，当用户将鼠标悬停或使用键盘选择剪贴板项时，在主窗口右侧显示一个 300x300 像素的浮动覆盖层，以居中方式显示该剪贴板项的完整内容预览。支持文本、图片和文件引用三种内容类型，采用 200ms 延迟触发和 150ms 去抖动优化性能。

**技术方法**: 使用 SwiftUI 创建浮动覆盖视图，通过监听剪贴板历史列表的悬停/选择状态来控制预览面板的显示和内容更新，集成到现有的 MVVM + Service 架构中。

## Technical Context

**Language/Version**: Swift 6.0
**Primary Dependencies**: SwiftUI (UI), AppKit (NSPanel, 窗口管理), Combine (Observable), SQLite.swift (数据访问)
**Storage**: SQLite 数据库（现有），图片文件系统存储（现有）
**Testing**: XCTest（单元测试和 UI 测试）
**Target Platform**: macOS 15.0+
**Project Type**: 单一项目（macOS 应用）
**Performance Goals**:
- 预览面板响应时间: < 200ms（悬停触发延迟）
- 预览面板更新去抖动: 150ms
- 图片加载性能: < 200ms（4K 图片降采样）
- 界面流畅度: 60fps

**Constraints**:
- 预览面板尺寸: 300x300 像素正方形
- 必须支持浮动覆盖布局，不影响主窗口宽度
- 限制在单显示器内显示
- 必须支持键盘导航（Tab/方向键）
- 必须实时响应剪贴板内容变化

**Scale/Scope**:
- 支持三种内容类型：文本、图片、文件引用
- 单预览面板实例
- 集成到现有剪贴板历史窗口

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. 用户体验至上 (User Experience First)
- **PASS**: 预览面板采用 200ms 延迟触发，符合快速响应要求
- **PASS**: 使用 150ms 去抖动优化快速切换性能
- **PASS**: 实时更新预览内容，保持数据一致性
- **PASS**: 支持键盘导航，提升可访问性

### ✅ II. 原生平台集成 (Native Platform Integration)
- **PASS**: 使用 SwiftUI + AppKit 构建
- **PASS**: 预览面板作为浮动层集成到现有 NSPanel 窗口
- **PASS**: 遵循 macOS 窗口管理最佳实践

### ✅ III. 架构清晰性 (Architectural Clarity)
- **PASS**: 遵循现有 MVVM + Service 架构
- **PASS**: 新增 PreviewPanelViewModel（视图状态）
- **PASS**: 新增 PreviewPanelView（UI 组件）
- **PASS**: 通过 ClipboardHistoryViewModel 协调预览状态

### ✅ IV. 数据完整性 (Data Integrity)
- **PASS**: 复用现有 SQLite 数据库和图片存储
- **PASS**: 实时监听剪贴板项变化，同步更新预览
- **PASS**: 无需新增数据模型或存储逻辑

### ✅ V. 搜索精确性 (Search Precision)
- **N/A**: 此功能不涉及搜索逻辑

**Gate Result**: ✅ **PASSED** - 所有宪法原则检查通过，无违规需要论证

## Project Structure

### Documentation (this feature)

```text
specs/001-clipboard-preview-panel/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (SwiftUI component interfaces)
└── tasks.md             # Phase 2 output (NOT created by this command)
```

### Source Code (repository root)

```text
Clipboard/
├── Models/
│   ├── ClipboardItem.swift          # 现有
│   ├── ClipboardItemType.swift      # 现有
│   └── PreviewPanelState.swift      # 新增：预览面板状态枚举
│
├── ViewModels/
│   ├── ClipboardHistoryViewModel.swift   # 现有：需扩展（添加预览状态管理）
│   └── PreviewPanelViewModel.swift      # 新增：预览面板视图模型
│
├── Views/
│   ├── ClipboardMainWindow.swift        # 现有：需集成预览面板
│   ├── ClipboardHistoryView.swift       # 现有：需添加悬停检测
│   ├── ClipboardItemRowView.swift       # 现有：需添加悬停状态跟踪
│   ├── PreviewPanelView.swift           # 新增：预览面板主视图
│   ├── PreviewTextView.swift            # 新增：文本预览组件
│   ├── PreviewImageView.swift           # 新增：图片预览组件
│   ├── PreviewFileView.swift            # 新增：文件引用预览组件
│   └── DesignSystem.swift               # 现有：可能需要扩展预览面板样式
│
├── Services/
│   ├── ClipboardMonitorService.swift    # 现有：复用（监听剪贴板变化）
│   └── ImageStorageService.swift        # 现有：复用（图片加载）
│
└── Utils/
    └── Debouncer.swift                  # 新增：去抖动工具（或使用现有实现）
```

**Structure Decision**: 采用单一项目结构（Option 1），这是现有 macOS 应用的标准布局。新增文件集中在 Views 层（预览相关组件）和 ViewModels 层（预览状态管理），最小化对现有代码的修改。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A - 所有宪法原则检查通过 |

**Note**: 无复杂度违规。设计遵循现有架构模式，新增功能为自然扩展。

---

## Phase 0: Research & Technical Decisions

### Research Tasks

1. **SwiftUI 浮动覆盖层实现模式**
   - 研究 SwiftUI 中实现浮动覆盖的最佳实践
   - 评估 `.overlay()` vs ZStack vs 独立 Window
   - 决定：使用 `.overlay()` 修饰符在主视图上添加浮动层

2. **悬停检测实现方案**
   - 研究 SwiftUI 中的 hover 检测方法
   - 评估 `.onHover()` vs GeometryReader + gesture
   - 决定：使用 `.onHover()` 修饰符监听列表项悬停事件

3. **键盘导航集成**
   - 研究如何在现有列表视图中跟踪键盘焦点
   - 评估 @FocusState vs 自定义焦点管理
   - 决定：扩展现有的键盘事件处理机制（ClipboardHistoryView 已支持键盘输入）

4. **性能优化策略**
   - 研究大图片加载和缩放的内存管理
   - 评估 ImageRenderer vs AsyncImage vs 手动图像处理
   - 决定：使用 ImageStorageService 的现有缩略图，大图片时降采样

5. **实时内容同步机制**
   - 研究如何监听剪贴板项的删除和更新
   - 评估 NotificationCenter vs Combine publishers
   - 决定：复用 ClipboardMonitorService 的现有通知机制

### Open Questions (Phase 0 必须解决)

- **Q1**: 预览面板的定位算法（屏幕边界检测）→ 需研究 GeometryReader 和屏幕坐标转换
- **Q2**: 去抖动实现方式 → 需确认是否使用 Combine 的 `.debounce()` 或自定义工具
- **Q3**: 多显示器边界检测的具体 API → 需研究 NSScreen API

**Output**: Phase 0 完成后将生成 `research.md`，包含所有技术决策的依据和实现细节。

---

## Phase 1: Design & Contracts

### Prerequisites
- `research.md` 完成，所有技术决策已确认

### Deliverables

#### 1. Data Model (`data-model.md`)
- **PreviewPanelState**: 状态枚举（隐藏、显示、加载中、错误）
- **PreviewContent**: 预览内容模型（封装 ClipboardItem + UI 状态）
- **HoverState**: 悬停状态模型（当前悬停项、悬停持续时间）

#### 2. Component Contracts (`contracts/`)
- **PreviewPanelView**: SwiftUI 视图接口（props、events、样式规范）
- **PreviewPanelViewModel**: 视图模型接口（状态、方法、Combine publishers）
- **ClipboardItemRowView**: 扩展接口（悬停回调）

#### 3. Quick Start Guide (`quickstart.md`)
- 开发环境设置
- 构建和运行步骤
- 关键文件说明
- 测试方法

#### 4. Agent Context Update
- 运行 `.specify/scripts/bash/update-agent-context.sh claude`
- 更新 AI 助手的项目上下文

**Output**: Phase 1 完成后将生成设计文档和接口契约，为 Phase 2 任务分解做好准备。

---

## Phase 2: Task Breakdown

**Note**: 此阶段由 `/speckit.tasks` 命令完成，不在本计划文档范围内。

预期任务类别：
1. 数据模型和状态管理
2. 预览面板视图实现
3. 悬停检测和事件处理
4. 键盘导航集成
5. 性能优化（去抖动、图片加载）
6. 边界情况处理（屏幕边界、内容更新）
7. 测试和验证

---

## Next Steps

1. ✅ **Current Phase**: 完成 `plan.md` 基础框架
2. ⏭️ **Next**: 执行 Phase 0 研究，生成 `research.md`
3. ⏭️ **Then**: 执行 Phase 1 设计，生成 `data-model.md` 和 `contracts/`
4. ⏭️ **Finally**: 运行 `/speckit.tasks` 生成可执行任务列表

**Command to continue**: 执行 Phase 0 研究任务（本命令流自动继续）

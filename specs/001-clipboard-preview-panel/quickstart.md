# Quick Start Guide: 剪贴板预览面板

**Feature**: 剪贴板预览面板 (001-clipboard-preview-panel)
**Branch**: `001-clipboard-preview-panel`
**Date**: 2025-01-18

## Overview

本指南帮助开发人员快速开始剪贴板预览面板功能的开发和测试。

---

## Prerequisites

### System Requirements
- macOS 15.0 或更高版本
- Xcode 16.0 或更高版本
- Swift 6.0 工具链

### Permissions
- 辅助功能权限（全局快捷键监听所需）

### Existing Dependencies
- SQLite.swift (>= 0.15.0)
- SwiftUI + AppKit 框架（系统自带）

---

## Development Setup

### 1. Checkout Feature Branch

```bash
cd /Users/huangchen/Develop/agent/Clipboard
git checkout 001-clipboard-preview-panel
```

### 2. Verify Project Structure

```bash
# 查看项目文件
ls -la Clipboard/
ls -la specs/001-clipboard-preview-panel/

# 应该看到以下文件：
# specs/001-clipboard-preview-panel/
# ├── plan.md
# ├── research.md
# ├── data-model.md
# ├── quickstart.md (本文件)
# ├── contracts/
# └── tasks.md (稍后生成)
```

### 3. Open in Xcode

```bash
open Clipboard.xcodeproj
# 或
open Clipboard.xcworkspace
```

### 4. Build and Run

```bash
# 命令行构建
swift build

# 或在 Xcode 中按 ⌘R 构建
```

---

## File Structure Overview

### 新增文件

```
Clipboard/
├── Models/
│   ├── PreviewPanelState.swift          # 预览面板状态枚举
│   ├── PreviewContent.swift             # 预览内容封装
│   └── HoverState.swift                 # 悬停状态跟踪
│
├── ViewModels/
│   └── PreviewPanelViewModel.swift      # 预览面板视图模型
│
├── Views/
│   ├── PreviewPanelView.swift           # 预览面板主视图
│   ├── PreviewTextView.swift            # 文本预览组件
│   ├── PreviewImageView.swift           # 图片预览组件
│   └── PreviewFileView.swift            # 文件引用预览组件
│
└── Utils/
    └── Debouncer.swift (可选)            # 去抖动工具
```

### 修改的文件

```
Clipboard/
├── ViewModels/
│   └── ClipboardHistoryViewModel.swift  # 扩展：添加预览状态管理
│
└── Views/
    ├── ClipboardMainWindow.swift        # 集成：添加预览面板覆盖层
    ├── ClipboardHistoryView.swift       # 集成：添加悬停检测
    ├── ClipboardItemRowView.swift       # 集成：添加悬停回调
    └── DesignSystem.swift               # 扩展：预览面板样式
```

---

## Key Components

### 1. PreviewPanelView (主视图)

**文件**: `Clipboard/Views/PreviewPanelView.swift`

**职责**:
- 根据 `ClipboardItem` 类型显示不同预览内容
- 管理显示/隐藏动画
- 处理左右定位切换

**关键属性**:
```swift
@ObservedController var viewModel: PreviewPanelViewModel
var shouldShowOnLeft: Bool = false
```

**使用示例**:
```swift
.overlay(alignment: .trailing) {
    PreviewPanelView(viewModel: previewPanelViewModel)
        .frame(width: 300, height: 300)
}
```

---

### 2. PreviewPanelViewModel (视图模型)

**文件**: `Clipboard/ViewModels/PreviewPanelViewModel.swift`

**职责**:
- 管理预览面板状态（`PreviewPanelState`）
- 加载预览内容（文本、图片、文件）
- 响应剪贴板项变化（通过 `NotificationCenter`）

**关键方法**:
```swift
func showPreview(for item: ClipboardItem)
func hidePreview()
func refreshPreviewContent()
```

**状态转换**:
```
.hidden → .loading → .showing(item)
                ↓
              .error(message)
```

---

### 3. ClipboardItemRowView Extension (悬停检测)

**文件**: `Clipboard/Views/ClipboardItemRowView.swift`

**新增职责**:
- 检测鼠标悬停（`.onHover()`）
- 通知 `ClipboardHistoryViewModel`
- 管理 200ms 延迟触发

**集成方式**:
```swift
var body: some View {
    HStack {
        // 现有内容
    }
    .onHover { isHovering in
        if isHovering {
            viewModel.onItemHovered(item)
        } else {
            viewModel.onItemExited()
        }
    }
}
```

---

## Implementation Workflow

### Phase 1: 数据模型和状态管理

1. **创建状态枚举**
   - 实现 `PreviewPanelState` 枚举
   - 实现 `PreviewContent` 结构体

2. **创建视图模型**
   - 实现 `PreviewPanelViewModel` 类
   - 添加 `@Observable` 支持
   - 实现 `showPreview()`, `hidePreview()` 方法

3. **扩展 ClipboardHistoryViewModel**
   - 添加 `hoverState` 属性
   - 实现 `onItemHovered()`, `onItemExited()` 方法

### Phase 2: 预览面板视图

1. **创建主视图**
   - 实现 `PreviewPanelView` 结构体
   - 添加状态切换逻辑（`.showing`, `.loading`, `.error`）
   - 应用样式（背景、圆角、阴影）

2. **创建内容组件**
   - 实现 `PreviewTextView`（文本预览）
   - 实现 `PreviewImageView`（图片预览）
   - 实现 `PreviewFileView`（文件引用预览）

### Phase 3: 悬停检测集成

1. **修改 ClipboardItemRowView**
   - 添加 `.onHover()` 修饰符
   - 实现 200ms 延迟触发逻辑
   - 集成焦点管理（键盘导航）

2. **修改 ClipboardHistoryView**
   - 添加 `.overlay()` 修饰符集成预览面板
   - 实现屏幕边界检测逻辑

### Phase 4: 性能优化

1. **实现去抖动**
   - 使用 Combine 的 `.debounce()` 操作符
   - 设置 150ms 延迟

2. **优化图片加载**
   - 优先使用缩略图
   - 按需加载原图

3. **添加实时同步**
   - 监听 `.clipboardItemDidUpdate` 通知
   - 监听 `.clipboardItemDidDelete` 通知

### Phase 5: 边界情况处理

1. **屏幕边界检测**
   - 实现 `GeometryReader` 坐标读取
   - 检测 `NSScreen` 边界
   - 自动切换左右位置

2. **内容更新处理**
   - 剪贴板项删除时显示提示
   - 剪贴板项更新时刷新预览

---

## Testing

### 单元测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter PreviewPanelViewModelTests
```

### UI 测试

1. **启动应用**
   ```bash
   swift run Clipboard
   ```

2. **触发全局快捷键**
   - 按 `⌃⌘V` 打开剪贴板历史窗口

3. **测试鼠标悬停**
   - 将鼠标悬停在列表项上
   - 等待 200ms，验证预览面板显示
   - 移动鼠标到其他项，验证内容更新

4. **测试键盘导航**
   - 使用方向键选择列表项
   - 验证预览面板立即显示（无延迟）

5. **测试边界情况**
   - 将窗口移动到屏幕右边缘
   - 验证预览面板自动切换到左侧
   - 悬停时删除剪贴板项，验证错误提示

### 性能测试

1. **响应时间**
   - 验证预览面板在 200ms 内显示
   - 使用 Instruments 测量实际延迟

2. **内存占用**
   - 使用 Instruments 监控内存
   - 验证内存占用在合理范围（< 100MB）

3. **流畅度**
   - 快速移动鼠标划过多个项
   - 验证界面保持 60fps

---

## Common Issues

### Issue 1: 预览面板不显示

**可能原因**:
- 悬停延迟未触发
- `PreviewPanelViewModel` 未正确初始化

**解决方案**:
- 检查 `.onHover()` 回调是否正确调用
- 验证 `panelState` 是否正确设置

### Issue 2: 预览内容不更新

**可能原因**:
- `@Observable` 未正确声明
- Combine pipeline 未建立

**解决方案**:
- 确保使用 `@ObservedController` 或 `@State`
- 检查 `.sink` 是否正确存储

### Issue 3: 性能问题

**可能原因**:
- 未使用去抖动
- 图片加载阻塞主线程

**解决方案**:
- 添加 `.debounce()` 操作符
- 使用 `.async` 异步加载图片

---

## Next Steps

1. ✅ **完成 Phase 1**: 数据模型和状态管理
2. ⏭️ **执行 Phase 2**: 预览面板视图实现
3. ⏭️ **执行 Phase 3**: 悬停检测集成
4. ⏭️ **执行 Phase 4**: 性能优化
5. ⏭️ **执行 Phase 5**: 边界情况处理
6. ⏭️ **运行测试**: 验证所有功能
7. ⏭️ **生成任务**: 运行 `/speckit.tasks` 生成详细任务列表

---

## Resources

### 设计文档
- [Feature Specification](./spec.md) - 功能规格
- [Implementation Plan](./plan.md) - 实施计划
- [Research](./research.md) - 技术研究
- [Data Model](./data-model.md) - 数据模型

### 代码契约
- [PreviewPanelView Contract](./contracts/PreviewPanelView.swift)
- [PreviewPanelViewModel Contract](./contracts/PreviewPanelViewModel.swift)
- [ClipboardItemRowView Extension](./contracts/ClipboardItemRowView+Preview.swift)

### 项目文档
- [Project Constitution](../../.specify/memory/constitution.md) - 项目宪章
- [CLAUDE.md](../../CLAUDE.md) - 项目指南

---

**Last Updated**: 2025-01-18
**Feature Branch**: 001-clipboard-preview-panel
**Status**: Ready for Implementation

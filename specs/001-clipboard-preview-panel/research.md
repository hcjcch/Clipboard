# Research: 剪贴板预览面板技术决策

**Feature**: 剪贴板预览面板 (001-clipboard-preview-panel)
**Date**: 2025-01-18
**Status**: ✅ Complete

## Overview

本文档记录了剪贴板预览面板功能的技术研究和设计决策，涵盖浮动覆盖层实现、悬停检测、键盘导航集成、性能优化和实时内容同步等关键领域。

---

## Decision 1: 浮动覆盖层实现模式

### 决策
使用 SwiftUI 的 `.overlay()` 修饰符在主窗口视图上添加浮动覆盖层。

### 理由
- **简洁性**: `.overlay()` 是 SwiftUI 原生支持，无需复杂的坐标计算
- **自动布局**: 覆盖层自动跟随父视图，窗口移动时无需手动更新位置
- **层级控制**: 通过 `.zIndex()` 可轻松控制覆盖层与其他 UI 元素的层级关系
- **性能**: SwiftUI 的渲染引擎自动优化覆盖层的重绘区域

### 技术实现
```swift
// 在 ClipboardHistoryView 中添加预览面板覆盖层
.overlay(alignment: .trailing) {
    PreviewPanelView(item: viewModel.hoveredItem)
        .frame(width: 300, height: 300)
        .opacity(viewModel.shouldShowPreview ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.15), value: viewModel.shouldShowPreview)
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|------|------|------|----------|
| ZStack | 完全控制层级 | 需要管理完整布局，代码冗余 | `.overlay()` 更简洁 |
| 独立 Window | 真正独立，无布局限制 | 需要手动同步位置和生命周期 | 复杂度高，不符合单一窗口模型 |
| GeometryReader | 精确定位 | 性能开销大，触发频繁重绘 | 过度设计，`.overlay()` 足够 |

---

## Decision 2: 悬停检测实现方案

### 决策
使用 SwiftUI 的 `.onHover()` 修饰符监听列表项悬停事件。

### 理由
- **原生支持**: SwiftUI 提供的悬停检测 API，无需额外实现
- **性能优化**: 系统级别的鼠标事件处理，比手势检测更高效
- **简洁代码**: 单行代码即可实现悬停检测

### 技术实现
```swift
// 在 ClipboardItemRowView 中添加悬停检测
.onHover { isHovering in
    if isHovering {
        viewModel.onItemHovered(item)
        startHoverTimer() // 200ms 延迟触发
    } else {
        viewModel.onItemExited()
        cancelHoverTimer()
    }
}
```

### 延迟触发实现
使用 `DispatchQueue` 实现悬停延迟：
```swift
private var hoverWorkItem: DispatchWorkItem?

func startHoverTimer() {
    hoverWorkItem?.cancel()
    let workItem = DispatchWorkItem {
        viewModel.showPreview()
    }
    hoverWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|------|------|------|----------|
| GeometryReader + gesture | 完全控制检测区域 | 性能开销大，代码复杂 | `.onHover()` 足够且更高效 |
| DragGesture | 可检测移动轨迹 | 仅在拖动时触发，不适合悬停 | 语义不匹配 |
| Timer 轮询 | 兼容性好 | 性能差，CPU 占用高 | 过时做法 |

---

## Decision 3: 键盘导航集成

### 决策
扩展现有的键盘事件处理机制（`ClipboardHistoryView` 已支持键盘输入），通过 `@FocusState` 跟踪列表焦点。

### 理由
- **现有基础**: 项目已有键盘事件监听（`NSEvent.addLocalMonitorForEvents`），可直接复用
- **SwiftUI 原生**: `@FocusState` 是 SwiftUI 推荐的焦点管理方式
- **一致性**: 与现有键盘导航（方向键选择项）保持一致的交互模式

### 技术实现
```swift
// 在 ClipboardHistoryViewModel 中扩展焦点管理
@Published var focusedItem: ClipboardItem?

func handleKeyNavigation(_ event: NSEvent) -> NSEvent? {
    switch event.keyCode {
    case 125: // 下箭头
        moveToNextItem()
        return nil // 消费事件
    case 126: // 上箭头
        moveToPreviousItem()
        return nil
    default:
        return event
    }
}

// 当焦点项改变时，触发预览
$focusedItem
    .debounce(for: .milliseconds(0), scheduler: RunLoop.main) // 键盘导航无需延迟
    .sink { [weak self] item in
        self?.showPreview(for: item)
    }
    .store(in: &cancellables)
```

### 列表项焦点绑定
```swift
// 在 ClipboardItemRowView 中
@Binding var isFocused: Bool

var body: some View {
    HStack {
        // 内容
    }
    .focused($isFocused)
    .onChange(of: isFocused) { _, newValue in
        if newValue {
            viewModel.onItemFocused(item)
        }
    }
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|------|------|------|----------|
| 自定义焦点管理 | 完全控制 | 需维护额外状态，易出错 | SwiftUI 提供了标准方案 |
| List 的 selection | 自动支持 | 样式受限，难自定义 | 需要完全自定义 UI |
| UITextInput | 标准协议 | 过于复杂，文档支持差 | 过度设计 |

---

## Decision 4: 性能优化策略

### 决策
1. **去抖动**: 使用 Combine 的 `.debounce()` 实现快速切换时的性能优化
2. **图片加载**: 复用 `ImageStorageService` 的现有缩略图，大图片时按需降采样
3. **视图复用**: 使用 SwiftUI 的视图复用机制（`id()` 修饰符）

### 4.1 去抖动实现

#### 决策
使用 Combine 的 `.debounce()` 操作符，而非自定义 `Debouncer` 类。

#### 理由
- **声明式**: Combine 提供响应式 API，代码更简洁
- **集成性**: 与现有的 `@Published` 属性天然配合
- **可测试性**: Combine publishers 易于单元测试

#### 技术实现
```swift
// 在 PreviewPanelViewModel 中
$hoveredItem
    .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
    .sink { [weak self] item in
        self?.updatePreviewContent(item)
    }
    .store(in: &cancellables)
```

### 4.2 图片加载优化

#### 决策
优先使用 `ImageStorageService` 的 60x60 缩略图，当用户长时间悬停（>500ms）时按需加载原图。

#### 理由
- **即时响应**: 缩略图已存在，加载时间 < 10ms
- **渐进增强**: 先显示低质量预览，再提升到高质量
- **内存控制**: 缩略图内存占用 < 100KB，原图可达数 MB

#### 技术实现
```swift
// 在 PreviewImageView 中
@State private var isLoadingHighRes = false

var body: some View {
    Group {
        if let thumbnail = item.thumbnailData {
            Image(nsImage: NSImage(data: thumbnail)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
        }
    }
    .onAppear {
        // 延迟加载原图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoadingHighRes = true
            loadHighResImage()
        }
    }
}
```

### 4.3 视图复用

#### 决策
使用 SwiftUI 的 `.id()` 修饰符确保不同内容类型的视图被正确重建。

#### 理由
- **类型切换**: 文本/图片/文件需要完全不同的视图层次
- **性能**: SwiftUI 会缓存和复用相同 ID 的视图
- **清晰性**: 明确标识视图的生命周期

#### 技术实现
```swift
// 在 PreviewPanelView 中
var body: some View {
    Group {
        switch item.type {
        case .text:
            PreviewTextView(item: item)
        case .image:
            PreviewImageView(item: item)
        case .file:
            PreviewFileView(item: item)
        }
    }
    .id(item.id) // 确保切换时重建
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|---------|------|------|----------|
| 自定义 Debouncer 类 | 完全控制 | 需维护额外状态 | Combine 的 `.debounce()` 足够 |
| LRU 缓存 | 缓存命中率高 | 增加复杂度，内存占用 | 缩略图已足够 |
| 预加载 | 无加载延迟 | 浪费带宽和内存 | 按需加载更合理 |

---

## Decision 5: 实时内容同步机制

### 决策
复用 `ClipboardMonitorService` 的现有 `NotificationCenter` 通知机制，监听剪贴板项的删除和更新事件。

### 理由
- **现有基础设施**: 项目已使用 `NotificationCenter` 传递剪贴板变化事件
- **解耦**: 视图模型无需直接依赖服务层，通过通知通信
- **可扩展**: 未来其他组件也可监听相同事件

### 技术实现
```swift
// 在 ClipboardMonitorService 中扩展现有通知
extension Notification.Name {
    static let clipboardItemDidUpdate = Notification.Name("clipboardItemDidUpdate")
    static let clipboardItemDidDelete = Notification.Name("clipboardItemDidDelete")
}

// 发送通知（在服务层）
func updateItem(_ item: ClipboardItem) {
    database.update(item)
    NotificationCenter.default.post(
        name: .clipboardItemDidUpdate,
        object: nil,
        userInfo: ["itemId": item.id]
    )
}

// 监听通知（在 PreviewPanelViewModel 中）
init() {
    NotificationCenter.default.publisher(for: .clipboardItemDidUpdate)
        .compactMap { $0.userInfo?["itemId"] as? String }
        .filter { [weak self] itemId in
            self?.currentItem?.id == itemId
        }
        .sink { [weak self] _ in
            self?.refreshPreviewContent()
        }
        .store(in: &cancellables)
}
```

### 删除项处理
```swift
NotificationCenter.default.publisher(for: .clipboardItemDidDelete)
    .compactMap { $0.userInfo?["itemId"] as? String }
    .filter { [weak self] itemId in
        self?.currentItem?.id == itemId
    }
    .sink { [weak self] _ in
        self?.showDeletedMessage()
    }
    .store(in: &cancellables)

func showDeletedMessage() {
    previewState = .error("该项已被删除")
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|------|------|------|----------|
| Combine PassthroughSubject | 类型安全 | 需要服务层暴露 Publisher | 增加耦合度 |
| 定时轮询 | 简单可靠 | 性能差，延迟高 | 推送模式更优 |
| AsyncStream | Swift 现代 API | 需要大量重构 | 现有通知机制已足够 |

---

## Decision 6: 屏幕边界检测与定位

### 决策
使用 `GeometryReader` 获取预览面板的全局坐标，结合 `NSScreen.screens` 检测屏幕边界，动态调整预览面板位置。

### 理由
- **准确性**: `GeometryReader` 提供精确的视图坐标
- **多显示器支持**: `NSScreen.screens` 可获取所有显示器信息
- **自动适应**: 窗口移动时自动重新计算位置

### 技术实现
```swift
// 在 PreviewPanelView 中
@State private var screenBounds: CGRect = .zero

var body: some View {
    GeometryReader { geometry in
        Color.clear
            .onAppear {
                updatePositionIfNeeded(geometry: geometry)
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                updatePositionIfNeeded(geometry: geometry)
            }
    }
}

func updatePositionIfNeeded(geometry: GeometryProxy) {
    let globalFrame = geometry.frame(in: .global)
    let panelRightEdge = globalFrame.maxX

    // 检测是否超出屏幕边界
    for screen in NSScreen.screens {
        let screenFrame = screen.visibleFrame
        if panelRightEdge > screenFrame.maxX {
            // 切换到左侧显示
            shouldShowOnLeft = true
            break
        }
    }
}

// 使用 alignment 控制显示位置
.overlay(alignment: shouldShowOnLeft ? .leading : .trailing) {
    PreviewPanelView(item: viewModel.hoveredItem)
}
```

### 多显示器限制
```swift
// 确保预览面板在主窗口所在显示器
func getScreenForWindow(_ window: NSWindow) -> NSScreen? {
    let windowCenter = NSPoint(x: window.frame.midX, y: window.frame.midY)
    return NSScreen.screens.first { screen in
        screen.frame.contains(windowCenter)
    }
}
```

### 其他考虑方案
| 方案 | 优点 | 缺点 | 拒绝原因 |
|------|------|------|----------|
| 固定偏移量 | 简单 | 不适应所有屏幕尺寸 | 用户体验差 |
| 仅检测主屏幕 | 实现简单 | 多显示器场景失效 | 不符合规格要求 |
| 手动坐标计算 | 完全控制 | 代码复杂，易出错 | `GeometryReader` 已足够 |

---

## Summary of Technical Decisions

| 决策领域 | 选择方案 | 关键技术 |
|---------|---------|---------|
| 浮动覆盖层 | `.overlay()` 修饰符 | SwiftUI 原生 API |
| 悬停检测 | `.onHover()` + DispatchQueue 延迟 | 系统级鼠标事件 |
| 键盘导航 | 扩展现有键盘处理 + `@FocusState` | 复用现有基础设施 |
| 去抖动 | Combine `.debounce()` | 响应式编程 |
| 图片加载 | 缩略图优先 + 按需原图 | 渐进增强策略 |
| 实时同步 | `NotificationCenter` | 解耦通信 |
| 屏幕边界 | `GeometryReader` + `NSScreen` | 精确定位 |

---

## Next Steps

Phase 0 研究完成，所有技术决策已确认：
- ✅ 所有 Open Questions 已解决
- ✅ 技术栈和实现方法已确定
- ✅ 性能优化策略已定义
- ✅ 可继续执行 Phase 1（设计和契约）

**Next**: 生成 `data-model.md` 和 `contracts/`

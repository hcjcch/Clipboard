# Phase 0 Research: 技术研究

**Feature**: 设置界面布局优化与快捷键自定义
**Date**: 2026-01-10

## 研究问题

基于 Technical Context 中的 NEEDS CLARIFICATION 项目，本研究解决以下问题：

1. **测试框架**: 当前项目未配置测试，是否需要添加 XCTest？
2. **UserDefaults 容量**: 用户设置数据量小，UserDefaults 是否足够？

---

## 研究问题 1: 测试框架

### 决策
不添加 XCTest 测试框架。

### 理由

1. **项目当前状态**: 检查 Package.swift，项目未配置测试目标，且现有代码（FuzzyMatcher、TextHighlighter）无测试覆盖。

2. **功能特性**: 本功能主要是 UI 交互和设置持久化，核心逻辑是：
   - 快捷键验证（简单逻辑：检查修饰键存在性）
   - 系统保留快捷键列表查找（简单的集合查找）
   这些逻辑复杂度低，手动测试即可覆盖。

3. **用户故事优先级**: 4 个用户故事都是独立的 UI 功能，可以通过手动测试验证：
   - P1: 快捷键自定义 - 直接测试快捷键输入和生效
   - P2: 状态栏访问设置 - 直接测试状态栏菜单
   - P3: 设置界面布局 - 直接验证 UI 布局
   - P4: 快捷键冲突检测 - 直接测试系统保留键拦截

4. **维护成本**: 添加 XCTest 需要：
   - 配置测试目标
   - 编写 UI 测试（fragile，易随 UI 变化而失败）
   - 维护测试代码的时间成本

### 替代方案

| 方案 | 说明 | 采用原因 |
|------|------|----------|
| 手动测试 | 每次更改后手动验证功能 | 功能简单，手动测试快速可靠 |
| 内置日志 | 在关键点添加 print 日志 | 已在现有代码中使用（如 HotKeyManager） |

**结论**: 不添加 XCTest。通过手动测试验证功能，关键逻辑添加日志辅助调试。

---

## 研究问题 2: UserDefaults 容量

### 决策
使用 UserDefaults 存储用户设置，无需迁移到其他存储方式。

### 理由

1. **数据量分析**: 本功能需要存储的数据：
   ```swift
   // 需要存储的数据
   - customHotKeyKeyCode: UInt32      // 4 bytes
   - customHotKeyModifiers: UInt32    // 4 bytes
   - customHotKeyDisplayName: String  // ~10 bytes (如 "⌃⌘V")
   ```
   总计约 20 bytes，远低于 UserDefaults 的限制。

2. **UserDefaults 限制**:
   - iOS/macOS: 无明确大小限制，建议 < 1MB
   - 读取速度: 极快（内存缓存）
   - 写入速度: 异步，不影响 UI 响应
   - 持久化: 系统自动处理，可靠

3. **当前项目使用情况**: 检查现有代码，项目已在多个地方使用 UserDefaults：
   - 系统偏好设置的标准存储方式
   - 与现有架构一致

4. **数据完整性需求**:
   - 用户设置数据量小且结构简单
   - 无需复杂查询或关系
   - 不需要事务支持
   - UserDefaults 已足够满足数据完整性要求

### 替代方案考虑

| 方案 | 优点 | 缺点 | 采用原因 |
|------|------|------|----------|
| UserDefaults | 简单、系统原生、快速 | 不适合大数据 | **采用** - 数据量小，够用 |
| SQLite | 结构化、可扩展 | 需要额外表和查询逻辑 | 过度设计，增加复杂度 |
| Property List (plist) | 结构化、可读 | 需要文件 I/O 代码 | UserDefaults 内部就是 plist，直接用更简单 |
| JSON 文件 | 灵活、可版本控制 | 需要序列化/反序列化 | 不必要，UserDefaults 自动处理 |

**结论**: 使用 UserDefaults 存储。实现时使用 `@AppStorage` 属性包装器简化代码。

---

## 其他技术研究

### SwiftUI 设置界面布局

**决策**: 使用 `NavigationSplitView` 实现左右布局。

**理由**:
- iOS 16+ / macOS 13+ 原生支持，符合项目最低版本要求（macOS 15.0）
- 自动处理侧边栏选择和内容切换
- 支持键盘导航和可访问性
- 符合 macOS 原生设计规范

**示例结构**:
```swift
NavigationSplitView {
    // 左侧：设置选项列表
    List(SettingsOption.allCases, selection: $selectedOption) { ... }
} detail: {
    // 右侧：选中选项的详细设置
    ...
}
```

### 快捷键录制控件

**决策**: 自定义 SwiftUI 视图，使用 `NSEvent` 本地监控捕获键盘事件。

**理由**:
- SwiftUI 没有内置的快捷键录制控件
- 需要捕获原始键盘事件（包括修饰键状态）
- 通过 `onAppear` 注册事件监控，`onDisappear` 取消注册

**实现要点**:
- 监听 `keyDown` 和 `flagsChanged` 事件
- 验证至少包含一个修饰键
- 将按键转换为显示名称（如 "⌃⌘V"）
- 支持 Escape 取消

### 系统保留快捷键列表

**决策**: 静态定义约 20 个常见 macOS 系统快捷键。

**理由**:
- macOS 系统快捷键是固定的，不需要动态获取
- 常见系统快捷键约 20 个，手动维护简单
- 检测逻辑：简单的集合查找，O(1) 时间复杂度

**列表包括**:
- ⌘Q (退出应用)
- ⌘⌫ (删除)
- ⌘W (关闭窗口)
- ⌘N (新建)
- ⌘O (打开)
- ⌘S (保存)
- ⌘Z (撤销)
- ⇧⌘Z (重做)
- ⌘X (剪切)
- ⌘C (复制)
- ⌘V (粘贴)
- ⌘A (全选)
- ⌘F (查找)
- ⌘P (打印)
- ⌘T (新标签页)
- ⌘, (打开设置)
- ⌘H (隐藏应用)
- ⌥⌘H (隐藏其他应用)
- ⌘M (最小化)
- ⌘Space (Spotlight 搜索)

### HotKeyManager 增强

**当前状态分析**:
- 现有 `HotKeyManager` 只支持硬编码的 `controlCommandV`
- 使用 Carbon 框架注册全局快捷键
- 单例模式，有回调机制

**增强方案**:
1. 添加 `register(hotKey: HotKey)` 方法支持动态快捷键
2. 添加 `updateHotKey(_ newHotKey: HotKey)` 方法实现快捷键热更新
3. 从 `UserSettingsService` 读取用户自定义快捷键
4. 注册失败时返回错误信息

**无需变更**:
- Carbon 框架的使用（符合原生平台集成原则）
- 单例模式（符合架构清晰性原则）
- 事件处理机制

---

## 技术决策总结

| 决策 | 选择 | 理由 |
|------|------|------|
| 测试框架 | 不添加 XCTest | 功能简单，手动测试足够 |
| 存储方式 | UserDefaults | 数据量小，够用且简单 |
| 设置界面布局 | NavigationSplitView | macOS 15.0 原生支持，符合设计规范 |
| 快捷键录制 | 自定义视图 + NSEvent | SwiftUI 无内置控件 |
| 系统保留键 | 静态列表 | 系统快捷键固定，简单可靠 |

---

## Phase 1 准备

本研究已解决所有 NEEDS CLARIFICATION，可以进入 Phase 1 设计阶段。

**更新后的 Technical Context**:
- **Testing**: 手动测试，关键逻辑添加日志
- **Storage**: UserDefaults（@AppStorage）

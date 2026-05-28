# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 项目概述

这是一个 macOS 剪贴板历史管理应用，使用 Swift 和 SwiftUI 开发。应用监听系统剪贴板变化，记录历史内容，并通过全局快捷键 `⌃⌘V` 快速访问。

## 构建和运行

```bash
# 构建项目
swift build

# 运行应用
swift run Clipboard

# 在 Xcode 中打开
open Clipboard.xcodeproj
```

**依赖**: 项目使用 SQLite.swift（通过 SPM 管理）

## 架构

项目采用 **MVVM + Service** 架构模式：

### 核心组件层次
- **Models**: `ClipboardItem`, `ClipboardItemType`, `MatchResult` - 数据模型定义
- **ViewModels**: `ClipboardItemViewModel`, `ClipboardHistoryViewModel` - 视图逻辑（单例 `.shared`）
- **Views**: SwiftUI 视图组件
  - `ClipboardMainWindow` - 窗口管理和 `ClipboardHistoryContentView`
  - `ClipboardHistoryView` - 历史列表主视图
  - `ClipboardItemRowView` - 单个剪贴板项视图
  - `SearchInputOverlay` - 搜索输入覆盖层（黄色胶囊样式）
  - `HiddenInputField` - 隐藏输入框（用于支持输入法）
- **Services**: 业务逻辑服务层（均为单例）
  - `DatabaseService` - SQLite 数据库操作
  - `ClipboardMonitorService` - 剪贴板变化监听（轮询 `NSPasteboard.changeCount`）
  - `HotKeyManager` - 全局快捷键管理（Carbon 框架）
  - `ImageStorageService` - 图片存储和缩略图生成
- **Utils**: 工具类
  - `FuzzyMatcher` - 模糊搜索（支持完全匹配、首字母缩写、前缀、近似匹配）
  - `TextHighlighter` - 文本高亮（基于 `AttributedString`）

### 设计模式
- **单例模式**: 所有 Service 和主要 ViewModel 都使用 `.shared` 单例
- **观察者模式**: 使用 `@Published` 和 `@ObservedObject` 实现响应式更新
- **通知中心**: 用于剪贴板变化通知 (`.clipboardDidChange`)

## 核心功能实现

### 搜索系统
应用使用**模糊匹配**进行搜索，支持以下策略（按优先级）：
1. **完全匹配** - 得分 1.0
2. **首字母缩写** - 如 "fh" 匹配 "feature/home"，得分 0.9-1.0
3. **前缀匹配** - 得分 0.8
4. **近似匹配** - 基于 Levenshtein 编辑距离，得分 0.5

关键词按空格分离，所有关键词都必须匹配。结果按得分排序。

**键盘输入处理**: 窗口显示时，直接监听键盘事件 (`NSEvent.addLocalMonitorForEvents`)，不使用可见的 TextField。可打印字符直接添加到搜索，ESC 清空搜索或关闭窗口。

### 剪贴板监听
- 使用轮询方式监听 `NSPasteboard.changeCount`，间隔 0.5 秒
- 支持三种类型：文本 (`.string`)、图片 (`.png`, `.tiff`)、文件 (`.fileURL`)
- 图片文件检测：PNG, JPG, JPEG, GIF, BMP, TIFF, WebP, HEIC, HEIF

### 图片处理
- 自动生成 60x60 缩略图
- 图片存储在 `Application Support` 目录
- 图片数据保存为文件（`imagePath` 存储文件 ID），`thumbnailData` 用于快速显示

### 窗口管理
- 使用 `NSPanel` 而非 `NSWindow`，支持在全屏应用上显示
- 关键配置：
  - `isFloatingPanel = true`
  - `becomesKeyOnlyIfNeeded = true`
  - `level = .popUpMenu`
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]`
- 失焦时自动隐藏（监听 `NSWindow.didResignKeyNotification`）
- 透明标题栏，隐藏标准窗口按钮

### 数据持久化
- SQLite 数据库，通过 SQLite.swift 访问
- 自动去重和清理（保持最多 1000 条记录）
- 表结构：id, content, type, createdAt, thumbnailData, imagePath

### 全局快捷键
- 使用 Carbon 框架注册
- 快捷键：`⌃⌘V`（Control + Command + V）
- 需要**辅助功能权限**才能工作

## 关键文件

```
Clipboard/
├── ClipboardApp.swift          # 应用入口，AppDelegate 设置
├── Models/
│   ├── ClipboardItem.swift     # 核心数据模型
│   ├── ClipboardItemType.swift
│   └── MatchResult.swift       # 模糊匹配结果
├── ViewModels/
│   ├── ClipboardItemViewModel.swift
│   └── ClipboardHistoryViewModel.swift  # filteredItems 实现搜索逻辑
├── Views/
│   ├── ClipboardMainWindow.swift    # ClipboardWindowManager 窗口管理
│   ├── ClipboardHistoryView.swift   # 主列表视图
│   ├── ClipboardItemRowView.swift
│   ├── SearchInputOverlay.swift     # 黄色搜索胶囊
│   ├── HiddenInputField.swift       # 支持输入法的隐藏输入框
│   └── DesignSystem.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── ClipboardMonitorService.swift
│   ├── HotKeyManager.swift
│   └── ImageStorageService.swift
└── Utils/
    ├── FuzzyMatcher.swift       # 模糊匹配核心算法
    └── TextHighlighter.swift    # 搜索结果高亮
```

## 开发注意事项

### 权限配置
首次运行需要授予**辅助功能权限**：
- 系统设置 → 隐私与安全性 → 辅助功能

### 窗口行为
- 窗口通过 `ClipboardWindowManager.shared.toggleWindow()` 切换
- 失焦自动隐藏
- 显示时清空搜索状态 (`searchText = ""`)

### 搜索开发
搜索逻辑在 `ClipboardHistoryViewModel.filteredItems` 中实现，直接调用 `FuzzyMatcher.match()`。如需修改搜索行为，主要修改：
- `FuzzyMatcher.swift` - 匹配算法
- `ClipboardHistoryViewModel.swift` - 过滤和排序逻辑

### 高亮显示
使用 `TextHighlighter.highlightedText()` 为搜索结果创建高亮的 `AttributedString`，传入 `ClipboardItemRowView` 显示。

## Active Technologies
- Swift 6.0 + SwiftUI (UI), AppKit (NSStatusItem, NSPanel), Carbon (全局快捷键注册) (001-settings-hotkey-layout)
- UserDefaults (用户设置持久化) (001-settings-hotkey-layout)
- Swift 6.0 + SwiftUI (UI), AppKit (NSPanel, NSStatusItem), Foundation (Localization, UserDefaults), Combine (Observable) (001-i18n-lang-switch)
- UserDefaults (语言设置), .lproj 文件 (本地化字符串资源), SQLite (剪贴板历史 - 不受语言切换影响) (001-i18n-lang-switch)
- Swift 6.0 + SwiftUI (UI), AppKit (NSPanel, 窗口管理), Combine (Observable), SQLite.swift (数据访问) (001-clipboard-preview-panel)
- SQLite 数据库（现有），图片文件系统存储（现有） (001-clipboard-preview-panel)

## Recent Changes
- 001-settings-hotkey-layout: Added Swift 6.0 + SwiftUI (UI), AppKit (NSStatusItem, NSPanel), Carbon (全局快捷键注册)

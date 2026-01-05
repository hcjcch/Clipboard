# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/claude-code) when working with code in this repository.

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

## 架构

项目采用 **MVVM + Service** 架构模式：

### 层次结构
- **Models**: `ClipboardItem`, `ClipboardItemType` - 数据模型定义
- **ViewModels**: `ClipboardItemViewModel`, `ClipboardHistoryViewModel` - 视图逻辑
- **Views**: `ClipboardMainWindow`, `ClipboardHistoryView`, `ClipboardItemRowView` - SwiftUI 视图
- **Services**: 业务逻辑服务层
  - `DatabaseService` - SQLite 数据库操作
  - `ClipboardMonitorService` - 剪贴板变化监听
  - `HotKeyManager` - 全局快捷键管理
  - `ImageStorageService` - 图片存储和缩略图生成

### 设计模式
- **单例模式**: 所有 Service 和主要 ViewModel 都使用 `.shared` 单例
- **观察者模式**: 使用 `@Published` 和 `@ObservedObject` 实现响应式更新
- **通知中心**: 用于组件间通信（如窗口关闭通知）

## 核心功能实现

### 剪贴板监听
- 使用轮询方式监听 `NSPasteboard.changeCount`，间隔 0.5 秒
- 支持三种类型：文本 (`.string`)、图片 (`.png`, `.tiff`)、文件 (`.fileURL`)

### 图片处理
- 支持格式：PNG, JPG, JPEG, GIF, BMP, TIFF, WebP, HEIC, HEIF
- 自动生成 60x60 缩略图
- 图片存储在 `Application Support` 目录

### 数据持久化
- SQLite 数据库，通过 SQLite.swift 访问
- 自动去重和清理（保持最多 1000 条记录）
- 支持全文搜索

### 全局快捷键
- 使用 Carbon 框架注册
- 需要**辅助功能权限**才能工作

## 关键文件

```
Clipboard/
├── ClipboardApp.swift          # 应用入口
├── Models/
│   ├── ClipboardItem.swift
│   └── ClipboardItemType.swift
├── ViewModels/
│   ├── ClipboardItemViewModel.swift
│   └── ClipboardHistoryViewModel.swift
├── Views/
│   ├── ClipboardMainWindow.swift
│   ├── ClipboardHistoryView.swift
│   ├── ClipboardItemRowView.swift
│   └── DesignSystem.swift
└── Services/
    ├── DatabaseService.swift
    ├── ClipboardMonitorService.swift
    ├── HotKeyManager.swift
    └── ImageStorageService.swift
```

## 开发注意事项

### 权限配置
首次运行需要授予**辅助功能权限**：
- 系统设置 → 隐私与安全性 → 辅助功能
- 或在 Xcode 中添加 `NSAppleEventsUsageDescription` 到 Info.plist

### 窗口行为
- 主窗口通过 `ClipboardWindowManager.shared` 管理
- 窗口失焦时自动隐藏（监听 `NSApplication.didResignActiveNotification`）
- 快捷键触发时显示并聚焦窗口

### 数据库操作
- 使用 `DatabaseService.shared` 访问数据库
- 所有数据库操作在主线程执行（小型应用）
- 表结构：id, content, type, createdAt, thumbnailData, imagePath

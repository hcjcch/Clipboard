<!--
SYNC IMPACT REPORT
==================
Version change: INITIAL → 1.0.0
Modified principles: N/A (initial version)
Added sections:
  - Core Principles (5 principles defined)
  - Platform Requirements
  - Development Standards
Removed sections: N/A (initial version)
Templates requiring updates:
  ✅ plan-template.md - Constitution Check section verified compatible
  ✅ spec-template.md - Requirements structure verified compatible
  ✅ tasks-template.md - Task organization verified compatible
Follow-up TODOs: None
-->

# Clipboard Constitution

## Core Principles

### I. 用户体验至上 (User Experience First)

- 应用响应速度必须保持在 100ms 以内（全局快捷键唤醒窗口）
- 窗口失焦必须自动隐藏，保持用户工作流不被打断
- 所有动画必须流畅（60fps），避免卡顿感
- 搜索结果必须实时更新，无需额外确认操作

**理由**: 剪贴板管理器是高频使用的工具应用，任何延迟都会显著影响用户体验。

### II. 原生平台集成 (Native Platform Integration)

- 必须使用 macOS 原生框架（AppKit、Carbon、SwiftUI）
- 全局快捷键必须通过 Carbon 框架注册，确保系统级响应
- 窗口必须使用 NSPanel 配置为浮动面板，支持全屏应用上显示
- 必须正确处理辅助功能权限，提供友好的权限引导

**理由**: 深度集成 macOS 平台能力是实现全局快捷键和系统级监听的唯一可靠方式。

### III. 架构清晰性 (Architectural Clarity)

- 必须遵循 MVVM + Service 分层架构
- Models 层只包含数据定义，无业务逻辑
- ViewModels 层处理视图状态和用户交互逻辑
- Services 层封装所有业务逻辑，采用单例模式
- Views 层只负责 UI 渲染，不直接访问 Services

**理由**: 清晰的分层架构使代码易于理解、测试和维护，单例 Service 避免了状态同步问题。

### IV. 数据完整性 (Data Integrity)

- 所有剪贴板内容必须在变化时立即持久化到 SQLite 数据库
- 图片必须生成缩略图以提高列表加载性能
- 历史记录必须自动去重和清理（保持最多 1000 条）
- 数据库操作必须使用 SQLite.swift 的类型安全接口

**理由**: 剪贴板数据是用户的重要信息，丢失或损坏会严重影响信任。

### V. 搜索精确性 (Search Precision)

- 必须实现模糊匹配算法，支持完全匹配、首字母缩写、前缀匹配和近似匹配
- 搜索结果必须按相关性得分排序
- 多关键词搜索时所有关键词都必须匹配（AND 逻辑）
- 匹配文本必须高亮显示

**理由**: 快速找到历史剪贴板内容是应用的核心价值，搜索体验直接影响使用效率。

## Platform Requirements

### 技术栈约束

- **语言**: Swift 6.0
- **最低支持**: macOS 15.0
- **UI 框架**: SwiftUI（主要） + AppKit（窗口和系统交互）
- **数据库**: SQLite.swift (>= 0.15.0)
- **构建系统**: Swift Package Manager

### 性能约束

- 窗口唤醒响应时间: < 100ms
- 搜索响应时间: < 50ms
- 图片缩略图生成: < 200ms
- 内存占用: < 100MB（空闲状态）
- 数据库记录上限: 1000 条

### 权限要求

- 辅助功能权限（必需）：全局快捷键和剪贴板监听
- 应用请求权限时必须提供清晰的说明和引导

## Development Standards

### 代码组织

```
Clipboard/
├── Models/          # 数据模型（纯数据结构）
├── ViewModels/      # 视图模型（@Observable, 状态管理）
├── Views/           # SwiftUI 视图组件
├── Services/        # 业务逻辑服务（单例 .shared）
└── Utils/           # 工具类和算法
```

### 命名约定

- 文件名使用 PascalCase（如 `ClipboardItem.swift`）
- 类和结构体使用 PascalCase
- 方法和变量使用 camelCase
- 私有方法前缀不使用下划线（Swift 使用访问控制修饰符）

### 错误处理

- 所有 Service 方法必须处理错误情况
- 数据库操作失败必须记录日志并优雅降级
- 用户不应看到崩溃或原始错误信息

### 单元测试（可选）

- 如果添加测试，重点测试 Utils 层的算法（如 FuzzyMatcher）
- 测试文件与源文件同名，添加 Tests 后缀

## Governance

### 修订流程

1. 任何原则的修改必须通过团队讨论
2. 重大原则变更（影响架构或技术栈）需要文档说明和迁移计划
3. 小修小补（澄清措辞）可直接修改并更新版本号

### 版本策略

- MAJOR: 移除或重新定义核心原则/架构
- MINOR: 新增原则或显著扩展指导内容
- PATCH: 澄清措辞、修正错误、非语义改进

### 合规检查

- 所有代码审查必须验证是否符合架构清晰性原则
- 性能相关的 PR 必须验证是否符合用户体验至上原则
- 平台集成变更必须验证是否符合原生平台集成原则

**版本**: 1.0.0 | **批准日期**: 2026-01-10 | **最后修订**: 2026-01-10

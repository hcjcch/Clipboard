# Data Model: 设置界面布局优化与快捷键自定义

**Feature**: 001-settings-hotkey-layout
**Date**: 2026-01-10

## Overview

本功能涉及 3 个核心数据模型：`UserSettings`（用户设置）、`HotKeyDefinition`（快捷键定义）、`SettingsOption`（设置选项枚举）。这些模型遵循项目 MVVM 架构，属于 Models 层。

---

## Entity: UserSettings

### 描述
用户设置的数据模型，包含所有用户可自定义的设置项。当前版本只包含自定义快捷键。

### 属性

| 属性名 | 类型 | 描述 | 默认值 | 验证规则 |
|--------|------|------|--------|----------|
| `customHotKey` | HotKeyDefinition | 用户自定义的全局快捷键 | `HotKeyDefinition.controlCommandV` | 必须通过系统保留键验证 |
| `isCustomHotKeyEnabled` | Bool | 是否使用自定义快捷键（false 表示使用默认） | `false` | N/A |

### 持久化
- **存储方式**: UserDefaults
- **键名**:
  - `customHotKeyKeyCode`: UInt32
  - `customHotKeyModifiers`: UInt32
  - `customHotKeyDisplayName`: String
  - `isCustomHotKeyEnabled`: Bool

### 状态图

```
[使用默认快捷键] ──(用户设置自定义快捷键)──> [使用自定义快捷键]
       │                                              │
       │(点击"恢复默认")                              │(点击"恢复默认")
       └──────────────────────────────────────────────┘
```

### 代码示例

```swift
struct UserSettings: Codable {
    var customHotKey: HotKeyDefinition
    var isCustomHotKeyEnabled: Bool

    static let `default` = UserSettings(
        customHotKey: .controlCommandV,
        isCustomHotKeyEnabled: false
    )
}
```

---

## Entity: HotKeyDefinition

### 描述
表示一个全局快捷键，包含 keyCode、modifiers 和显示名称。

### 属性

| 属性名 | 类型 | 描述 | 验证规则 |
|--------|------|------|----------|
| `keyCode` | UInt32 | Carbon 框架的虚拟键码 | 必须是有效的键码（0-255） |
| `modifiers` | UInt32 | 修饰键标志位（cmdKey、controlKey、optionKey、shiftKey） | 必须至少包含一个修饰键 |
| `displayName` | String | 用户友好的显示名称（如 "⌃⌘V"） | 非空 |

### 预定义值

| 名称 | keyCode | modifiers | displayName |
|------|---------|-----------|-------------|
| `controlCommandV` | `kVK_ANSI_V` (9) | `cmdKey \| controlKey` | "⌃⌘V" |

### 验证规则

1. **有效性检查**: 至少包含一个修饰键
2. **冲突检查**: 不在系统保留快捷键列表中
3. **显示名称格式**: 修饰键在前，字符键在后

### 代码示例

```swift
struct HotKeyDefinition: Equatable, Codable {
    let keyCode: UInt32
    let modifiers: UInt32
    let displayName: String

    static let controlCommandV = HotKeyDefinition(
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | controlKey),
        displayName: "⌃⌘V"
    )

    /// 验证快捷键是否有效（至少包含一个修饰键）
    var isValid: Bool {
        return (modifiers & (cmdKey | controlKey | optionKey | shiftKey)) != 0
    }
}
```

---

## Entity: SettingsOption (Enum)

### 描述
设置界面左侧导航的选项枚举。

### 值

| 值 | 显示名称 | 图标 (SF Symbol) | 描述 |
|----|---------|------------------|------|
| `hotkey` | "快捷键" | "command" | 快捷键设置选项 |

### 代码示例

```swift
enum SettingsOption: String, CaseIterable, Identifiable {
    case hotkey

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hotkey: return "快捷键"
        }
    }

    var iconName: String {
        switch self {
        case .hotkey: return "command"
        }
    }
}
```

---

## Data Relationships

```
UserSettings
    │
    ├── contains ──> HotKeyDefinition (1:1)
    │
    └── persisted via ──> UserDefaults

SettingsOption
    │
    └── used by ──> SettingsViewModel (displayed in sidebar)
```

---

## Validation Rules

### HotKeyDefinition 验证

1. **修饰键检查**: 必须至少包含 ⌃、⌥、⇧、⌘ 中的一个
2. **系统保留键检查**: 不能与约 20 个 macOS 系统快捷键冲突
3. **字符键检查**: keyCode 必须在有效范围内（非功能键特殊处理）

### 验证流程

```
[用户输入] → [检查修饰键] → [通过？] → NO → [显示错误提示]
                    │
                    YES
                    ↓
            [检查系统保留键] → [通过？] → NO → [显示冲突提示]
                    │
                    YES
                    ↓
            [保存到 UserDefaults]
```

---

## Migration Strategy

### 版本 1.0 → 1.1 (添加自定义快捷键)

**新增字段**:
- `customHotKeyKeyCode`
- `customHotKeyModifiers`
- `customHotKeyDisplayName`
- `isCustomHotKeyEnabled`

**迁移策略**:
- 新安装用户：使用默认值
- 现有用户升级：UserDefaults 读取失败时使用默认值
- 无需数据迁移脚本（向后兼容）

---

## State Management

### SettingsViewModel 状态

```swift
@Observable class SettingsViewModel {
    // 当前选中的设置选项
    var selectedOption: SettingsOption = .hotkey

    // 用户设置（从 UserSettingsService 读取）
    var userSettings: UserSettings = .default

    // UI 状态
    var isRecordingHotKey: Bool = false
    var hotKeyError: HotKeyError?
}

enum HotKeyError: Error {
    case noModifier
    case systemReserved
}
```

---

## Notes

1. **线程安全**: UserSettingsService 通过 `@MainActor` 确保主线程访问
2. **默认值**: 所有模型都有合理的默认值，防止空状态
3. **Codable**: 支持 Codable 以便未来扩展到文件存储
4. **不可变性**: HotKeyDefinition 是 struct，属性不可变，确保数据一致性
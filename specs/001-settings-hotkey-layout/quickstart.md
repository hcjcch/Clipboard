# Quickstart Guide: 设置界面布局优化与快捷键自定义

**Feature**: 001-settings-hotkey-layout
**Date**: 2026-01-10

## 功能概览

本功能允许用户自定义呼出剪贴板历史的全局快捷键。设置界面采用左右布局，通过状态栏图标访问。

## 用户操作流程

### 打开设置界面

1. 点击菜单栏状态栏图标
2. 在下拉菜单中选择"设置"
3. 设置界面打开，显示"快捷键"设置面板

### 修改快捷键

1. 在快捷键设置面板，点击"录制"按钮或快捷键输入框
2. 按下新的组合键（必须包含至少一个修饰键：⌃、⌥、⇧、⌘）
3. 系统显示捕获的快捷键（如 "⌥⌘V"）
4. 快捷键立即生效，无需重启应用
5. 关闭设置界面时自动保存

### 恢复默认快捷键

点击"恢复默认"按钮，快捷键重置为 `⌃⌘V`。

### 错误处理

- **无效快捷键**: 如果只按字符键没有修饰键，显示"请使用有效的组合键（至少包含一个修饰键）"
- **系统保留快捷键**: 如果按下 ⌘Q、⌘⌫ 等系统快捷键，显示"此快捷键已被系统使用，请选择其他组合键"
- **取消录制**: 按 Escape 键或点击输入框外部取消录制

---

## 开发者快速开始

### 构建项目

```bash
cd /Users/huangchen/Develop/agent/Clipboard
swift build
```

### 运行应用

```bash
swift run Clipboard
```

### 权限配置

首次运行需要授予**辅助功能权限**：
1. 打开"系统设置" → "隐私与安全性" → "辅助功能"
2. 找到 Clipboard 应用并启用

### 测试快捷键

1. 运行应用后，状态栏会显示图标
2. 点击状态栏图标，选择"设置"
3. 尝试设置新的快捷键（如 `⌥⌘V`）
4. 在任意应用中按下新快捷键，验证剪贴板历史窗口是否呼出

---

## 文件结构概览

### 新增文件

```
Clipboard/
├── Models/
│   ├── UserSettings.swift              # 用户设置数据模型
│   └── HotKeyDefinition.swift          # 快捷键定义模型
├── ViewModels/
│   └── SettingsViewModel.swift         # 设置界面视图模型
├── Views/
│   ├── HotKeyRecorderView.swift        # 快捷键录制控件
│   └── SettingsSidebarView.swift       # 设置界面左侧导航
├── Services/
│   └── UserSettingsService.swift       # 用户设置服务
└── Utils/
    └── SystemHotKeyValidator.swift     # 系统保留快捷键验证器
```

### 修改文件

```
Clipboard/
├── Views/
│   ├── SettingsView.swift              # 重写为左右布局
│   └── SettingsWindowManager.swift     # 增强窗口管理
└── Services/
    ├── HotKeyManager.swift             # 增强支持自定义快捷键
    └── StatusBarManager.swift          # 添加"设置"菜单项
```

---

## 核心组件说明

### 1. UserSettingsService (Service)

用户设置的持久化和读取服务。

**职责**:
- 从 UserDefaults 读取用户设置
- 保存用户设置到 UserDefaults
- 提供默认值

**使用方式**:
```swift
let service = UserSettingsService.shared
let settings = service.userSettings  // 读取
service.saveUserSettings(newSettings) // 保存
```

### 2. SettingsViewModel (ViewModel)

设置界面的视图模型，管理 UI 状态。

**职责**:
- 管理当前选中的设置选项
- 处理快捷键录制状态
- 验证快捷键有效性
- 保存设置更改

**使用方式**:
```swift
@State private var viewModel = SettingsViewModel()
```

### 3. HotKeyRecorderView (View)

快捷键录制控件，捕获用户键盘输入。

**职责**:
- 监听键盘事件（NSEvent）
- 显示捕获的快捷键
- 验证快捷键有效性
- 支持 Escape 取消

**使用方式**:
```swift
HotKeyRecorderView(
    currentHotKey: $viewModel.userSettings.customHotKey,
    isRecording: $viewModel.isRecordingHotKey,
    onHotKeyRecorded: { newHotKey in
        viewModel.updateHotKey(newHotKey)
    }
)
```

### 4. SystemHotKeyValidator (Util)

系统保留快捷键验证器。

**职责**:
- 维护系统保留快捷键列表（约 20 个）
- 检查快捷键是否冲突

**使用方式**:
```swift
let validator = SystemHotKeyValidator()
if validator.isSystemReserved(hotKey) {
    // 显示冲突提示
}
```

---

## UserDefaults 存储结构

```swift
// UserDefaults Keys
enum UserDefaultsKey {
    static let customHotKeyKeyCode = "customHotKeyKeyCode"
    static let customHotKeyModifiers = "customHotKeyModifiers"
    static let customHotKeyDisplayName = "customHotKeyDisplayName"
    static let isCustomHotKeyEnabled = "isCustomHotKeyEnabled"
}

// 存储示例
UserDefaults.standard.set(9, forKey: .customHotKeyKeyCode)           // V键
UserDefaults.standard.set(0x110000, forKey: .customHotKeyModifiers)  // ⌃+⌘
UserDefaults.standard.set("⌃⌘V", forKey: .customHotKeyDisplayName)
UserDefaults.standard.set(true, forKey: .isCustomHotKeyEnabled)
```

---

## 调试技巧

### 查看 UserDefaults 内容

```swift
// 在调试时打印所有用户设置
let settings = UserSettingsService.shared.userSettings
print("Custom HotKey: \(settings.customHotKey.displayName)")
print("Is Enabled: \(settings.isCustomHotKeyEnabled)")
```

### 验证快捷键注册

```swift
// HotKeyManager 会打印日志
// 注册成功: "已注册快捷键: ⌃⌘V"
// 注册失败: "注册快捷键失败: [错误码]"
```

### 重置所有设置

```bash
# 删除应用的所有 UserDefaults 数据
defaults delete com.yourcompany.Clipboard
```

---

## 常见问题

### Q: 快捷键不生效？

1. 检查是否授予了辅助功能权限
2. 查看控制台日志确认快捷键是否注册成功
3. 尝试重启应用

### Q: 设置界面打不开？

1. 检查状态栏图标是否可见
2. 确认 SettingsWindowManager 是否正确初始化

### Q: 快捷键冲突检测不准确？

1. 检查 SystemHotKeyValidator 的系统保留键列表是否完整
2. 查看日志确认检测逻辑是否正确执行

---

## 性能目标

| 指标 | 目标 | 验证方式 |
|------|------|----------|
| 设置界面打开响应 | < 100ms | 从点击菜单到窗口显示的时间 |
| 快捷键保存和应用 | < 50ms | 从按下快捷键到生效的时间 |
| 窗口切换动画 | 60fps | 视觉流畅度 |
| 系统保留键拦截 | 100% | 尝试设置系统快捷键被拒绝 |

---

## 下一步

实现完成后，可以添加更多设置选项：
- 历史记录数量限制
- 主题选择（浅色/深色/自动）
- 自动清理策略
- 启动时运行选项

这些功能可以复用当前的左右布局结构，只需在 SettingsOption 枚举中添加新的 case。
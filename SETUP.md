# Clipboard 剪贴板应用 - 设置说明

## 项目结构

所有核心文件已创建完成：

```
Clipboard/
├── Models/
│   ├── ClipboardItem.swift          # 剪贴板项数据模型
│   └── ClipboardItemType.swift      # 内容类型枚举
├── ViewModels/
│   ├── ClipboardItemViewModel.swift # 单项 ViewModel
│   └── ClipboardHistoryViewModel.swift # 历史列表 ViewModel
├── Views/
│   ├── ClipboardItemRowView.swift   # 单项视图
│   ├── ClipboardHistoryView.swift   # 历史列表视图
│   └── ClipboardMainWindow.swift    # 主窗口管理
├── Services/
│   ├── DatabaseService.swift        # SQLite 数据库服务
│   ├── ClipboardMonitorService.swift # 剪贴板监听服务
│   └── HotKeyManager.swift          # 全局快捷键管理
├── Clipboard.entitlements           # 权限配置（已配置）
└── ClipboardApp.swift               # 应用入口
```

## ✅ 已完成的配置

- **SQLite.swift 依赖** - 已添加到项目
- **Entitlements 权限** - 已配置 Apple Events 权限

## 需要手动完成的步骤

### 1. 在 Xcode 中添加 Info 权限

由于项目使用自动生成的 Info.plist，需要在 Xcode 项目设置中添加：

1. 打开 `Clipboard.xcodeproj`
2. 选择项目导航器中的 **Clipboard** 项目
3. 选择 **Clipboard** target
4. 切换到 **Info** 标签
5. 在 "Custom iOS Target Properties" 或 "Custom macOS Target Properties" 中点击 **+** 添加：
   ```
   Key: NSAppleEventsUsageDescription
   Type: String
   Value: 需要辅助功能权限以使用全局快捷键
   ```

### 2. 系统权限授权

首次运行应用时，需要在系统设置中授权：

**辅助功能权限**（用于全局快捷键）：
1. 打开 **系统设置** → **隐私与安全性** → **辅助功能**
2. 找到 **Clipboard** 应用
3. 确保开关已打开

### 3. 构建和运行

在 Xcode 中按 `Cmd + R` 构建并运行应用。

## 功能说明

| 功能 | 说明 |
|------|------|
| 剪贴板监听 | 自动监听系统剪贴板变化 |
| 历史记录 | 存储剪贴板历史到 SQLite 数据库（最多 1000 条） |
| 快捷键呼出 | 按 `⌃⌘V` 呼出/隐藏剪贴板历史窗口 |
| 搜索功能 | 在历史记录中搜索文本内容 |
| 复制到剪贴板 | 点击任意项即可复制 |
| 删除项 | 右键菜单可删除单个项 |
| 失焦隐藏 | 窗口失去焦点时自动隐藏 |

## 故障排查

### 快捷键不工作
- 确保没有其他应用占用 `⌃⌘V` 快捷键
- 检查系统设置 → 隐私与安全性 → 辅助功能，确保已授权
- 尝试重启应用

### 剪贴板监听不工作
- 确保应用有必要的系统权限
- 检查控制台日志是否有错误信息

### 数据库错误
- 确保 SQLite.swift 依赖已正确添加（已在项目中配置）
- 检查应用支持目录是否有写入权限

### 编译错误
- 确保使用 Xcode 16.4 或更高版本
- 清理构建文件夹（Product → Clean Build Folder，按 `Cmd + Shift + K`）
- 重新构建

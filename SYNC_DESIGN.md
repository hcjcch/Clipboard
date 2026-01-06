# 跨平台双通道剪贴板同步 - 技术实现方案

## 项目概述

实现一个完全本地化的跨设备剪贴板同步系统，支持 macOS、iOS、Android 三平台，通过 WiFi 局域网和蓝牙双通道进行数据同步。

**核心特性**：
- 🔒 完全本地化，无需云端，数据不出设备
- ⚡ 双通道智能切换：WiFi 用于大文件，蓝牙用于实时同步
- 🔐 端到端加密，保护隐私安全
- 🔄 增量同步，基于向量时钟的冲突解决
- 📱 跨平台支持，代码高度复用

---

## 技术选型

### 平台技术栈

| 平台 | 语言 | UI 框架 | 最低版本 | 理由 |
|------|------|---------|----------|------|
| **macOS** | Swift 5.10+ | SwiftUI | macOS 15.0+ | 现有架构保持 |
| **iOS** | Swift 5.10+ | SwiftUI | iOS 17.0+ | 与 macOS 80%+ 代码共享 |
| **Android** | Kotlin | Jetpack Compose | Android 8.0+ (API 26+) | 现代化 UI，与 SwiftUI 思路一致 |

### 通信技术

| 通道 | 技术 | 用途 | 数据类型 |
|------|------|------|----------|
| **WiFi 局域网** | 自定义 TCP + Protocol Buffers | 大文件、历史记录 | 图片 > 100KB、批量数据 |
| **蓝牙** | MultipeerConnectivity (iOS/macOS)<br>BLE (Android) | 实时剪贴板 | 文本、小图片 < 100KB |

### 设备发现

- **mDNS (Bonjour)**: 跨平台标准，零配置
- **BLE 广播**: 低功耗，穿透性强

### 数据序列化

- **Protocol Buffers**: 二进制格式，体积小 30-50%，速度快 5-10x

---

## 技术选型详解

### 为什么选择原生开发而非 Flutter？

#### 核心问题：本项目的技术难点

剪贴板同步系统需要大量系统级 API 访问：
- **剪贴板监听**: 需要持续后台运行，需要精细的系统权限控制
- **蓝牙通信**: 需要处理低级连接、配对、数据分片、MTU 限制
- **WiFi TCP**: 需要自定义协议、断点续传、心跳保活
- **系统权限**: 辅助功能权限、蓝牙权限、局域网访问

#### Flutter vs 原生对比

| 维度 | Flutter | 原生方案 | 结论 |
|------|---------|----------|------|
| **代码复用率** | 90%+ 三端共用 | macOS/iOS: 80%+ 共用 | Flutter 略胜 |
| **性能** | Dart VM/编译后约原生 80% | 100% 原生性能 | **原生胜** |
| **蓝牙低级 API** | 需要插件，功能受限 | 直接调用 CoreBluetooth/Android BLE | **原生胜** |
| **系统权限** | Info.plist 配置复杂 | 原生权限声明清晰 | **原生胜** |
| **剪贴板监听** | 需要平台通道桥接 | 直接调用 NSPasteboard/ClipboardManager | **原生胜** |
| **MultipeerConnectivity** | 无对应插件，需自实现 | macOS/iOS 原生支持 | **原生胜** |
| **开发成本** | 需要学习 Dart、Flutter 生态 | 现有 Swift 代码可直接复用 | **原生胜** |
| **包体积** | Flutter Engine ~15MB | 原生无额外开销 | **原生胜** |
| **调试体验** | 跨语言栈追踪困难 | 单语言栈，工具链完善 | **原生胜** |

#### Flutter 的技术债务

如果选择 Flutter：
- **短期**: 需要学习 Dart、Flutter 生态，现有 Swift 代码无法复用
- **中期**: 大量平台通道代码桥接，调试跨语言栈困难
- **长期**: 维护两套代码（Swift 历史债务 + Flutter 新代码），包体积增加 15MB+

#### 原生方案的优势

1. **现有代码复用**: macOS 应用已成熟，Services 层（剪贴板监听、数据库、图片存储）可直接复用到 iOS（80%+）
2. **系统功能完整**: 蓝牙、WiFi、剪贴板、权限管理全部原生支持
3. **性能最优**: 无 VM、无桥接、无开销
4. **调试体验**: 单语言栈，Xcode/Android Studio 完善支持

#### SwiftUI vs Jetpack Compose

两套 UI 框架的思路几乎一致，代码可以"翻译"而非重写：

```swift
// SwiftUI
VStack(spacing: 8) {
    Text("Hello")
        .font(.title)
}
```

```kotlin
// Jetpack Compose
Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
    Text("Hello")
        .fontSize(20.sp)
}
```

**结论**: 保持原计划使用原生开发。

---

### 为什么选择自定义 TCP 而非 WebSocket？

#### WebSocket 的核心问题

WebSocket 设计初衷是**浏览器-服务器**通信，它的协议包括：
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: xxx
...
```

对于**局域网 P2P** 场景，这完全是多余的：
- **HTTP 握手浪费**: 局域网内设备发现后直接 TCP 连接更快
- **帧格式开销**: WebSocket 帧有 mask、opcode 等字段，增加 ~10% 开销
- **Base64 编码**: WebSocket 只能传文本，二进制数据需要 Base64（+33% 体积）

#### WebSocket vs 自定义 TCP 对比

| 维度 | WebSocket | 自定义 TCP | 结论 |
|------|-----------|------------|------|
| **协议开销** | HTTP 握手 + 帧格式 | 零开销 | **TCP 胜** |
| **二进制数据** | Base64 编码（+33%） | 原始字节 | **TCP 胜** |
| **P2P 发现** | 需要中心服务器 | mDNS 直连 | **TCP 胜** |
| **Protocol Buffers** | 需要序列化为 Base64 | 直接写入 TCP | **TCP 胜** |
| **局域网延迟** | 2-5ms（HTTP 解析） | <1ms（直连） | **TCP 胜** |
| **分片传输** | 需要应用层实现 | 可在协议层实现 | 平手 |
| **断点续传** | 需要应用层实现 | 可在协议层实现 | 平手 |

#### 自定义 TCP 协议设计

```swift
// 自定义协议，简单直接
struct SyncPacket {
    let type: MessageType      // 1 byte
    let length: Int32          // 4 bytes
    let payload: Data          // N bytes
    let checksum: UInt32       // 4 bytes
}

// 直接写入 TCP
socket.write(packet.rawBytes)
```

#### 数据传输效率对比

假设传输 1MB 图片：
- **WebSocket**: 18 bytes 帧头 + Base64 编码 = **~1.35MB**（+35%）
- **自定义 TCP**: 9 bytes 协议头 = **~1MB**（<1% 开销）

#### WebSocket 的适用场景

WebSocket 适合以下场景：
- ✅ 浏览器需要与服务器实时通信
- ✅ 需要穿越防火墙（利用 HTTP 端口）
- ✅ 客户端是 Web 应用

**本项目不需要这些**：局域网 P2P、原生应用、无需穿越防火墙。

**结论**: 保持原计划使用自定义 TCP。

---

## 技术选型总结

| 技术选型 | 决定 | 理由 |
|----------|------|------|
| **客户端框架** | 原生（Swift/Kotlin） | 现有代码复用、系统 API 完整、性能最优 |
| **WiFi 传输** | 自定义 TCP | 零开销、二进制友好、P2P 直连 |
| **数据序列化** | Protocol Buffers | 体积小、速度快、跨语言支持 |
| **设备发现** | mDNS + BLE | 跨平台标准、零配置、低功耗 |
| **UI 框架** | SwiftUI + Jetpack Compose | 现代化、代码思路一致 |

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    跨平台剪贴板同步系统                        │
└─────────────────────────────────────────────────────────────┘

        macOS                    iOS                    Android
    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐
    │  SwiftUI UI │         │  SwiftUI UI │         │ Jetpack UI  │
    └──────┬──────┘         └──────┬──────┘         └──────┬──────┘
           │                       │                       │
    ┌──────▼───────────────────────▼───────────────────────▼──────┐
    │                   Service Layer (共享业务逻辑)                │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
    │  │  Clipboard   │  │    Sync      │  │   Device     │      │
    │  │  Monitor     │  │  Manager     │  │  Discovery   │      │
    │  └──────────────┘  └──────┬───────┘  └──────────────┘      │
    └─────────────────────────────┼──────────────────────────────┘
                                  │
    ┌─────────────────────────────┼──────────────────────────────┐
    │                    Sync Layer (同步核心)                     │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
    │  │    WiFi      │  │   Bluetooth  │  │   Conflict   │      │
    │  │   Channel    │  │   Channel    │  │  Resolver    │      │
    │  └──────┬───────┘  └──────┬───────┘  └──────────────┘      │
    └─────────┼──────────────────┼──────────────────────────────┘
              │                  │
    ┌─────────▼──────────────────▼──────────────────────────────┐
    │                  Network Layer (网络层)                     │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
    │  │  mDNS/Bonjour│  │  Multipeer   │  │   Custom     │      │
    │  │  Discovery   │  │  Connect.    │  │    TCP       │      │
    │  └──────────────┘  └──────────────┘  └──────┬───────┘      │
    └───────────────────────────────────────────┼──────────────┘
                                                   │
    ┌──────────────────────────────────────────────▼─────────────┐
    │                  Data Layer (数据层)                         │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
    │  │   SQLite     │  │  Image       │  │  Protobuf    │      │
    │  │  Database    │  │  Storage     │  │  Codec       │      │
    │  └──────────────┘  └──────────────┘  └──────────────┘      │
    └────────────────────────────────────────────────────────────┘
```

---

## 数据模型扩展

### ClipboardItem 增强字段

```swift
extension ClipboardItem {
    struct SyncMetadata: Codable {
        let deviceId: String           // 设备唯一标识
        let deviceName: String         // 设备名称
        let version: Int32             // 版本号（冲突解决）
        let isSynced: Bool             // 是否已同步
        var syncedTo: [String]         // 已同步到的设备 ID 列表
        let checksum: String?          // 内容校验和（SHA256）
    }

    var syncMetadata: SyncMetadata?
}
```

### 设备信息模型

```swift
struct DeviceInfo: Codable, Identifiable {
    let id: String                    // UUID
    var name: String                  // 用户可编辑的设备名
    let platform: Platform            // macOS/iOS/Android
    let osVersion: String
    let appVersion: String
    let capabilities: Capabilities    // 支持的功能
    var lastSeen: Date                // 最后在线时间
    var isOnline: Bool
    var isTrusted: Bool               // 是否已信任
}
```

### 版本控制（向量时钟）

```swift
struct VectorClock: Codable {
    private var versions: [String: Int64]  // deviceId -> version

    mutating func increment(for deviceId: String)
    mutating func merge(_ other: VectorClock)
    func compare(_ other: VectorClock) -> Ordering

    enum Ordering {
        case before    // 当前时钟早于目标
        case after     // 当前时钟晚于目标
        case equal     // 相等
        case concurrent // 并发（冲突）
    }
}
```

---

## 核心功能模块

### 1. 设备发现与配对

#### mDNS 服务（跨平台）
- **macOS/iOS**: NetService/NetServiceBrowser
- **Android**: NsdManager/JmDNS
- 服务类型: `_clipboard._tcp.`
- TXT 记录: deviceId, platform, name, capabilities

#### 配对流程
1. 设备 A 发现设备 B（通过 mDNS 或 BLE）
2. 发起配对请求
3. 显示 6 位配对码（两个设备都显示）
4. 用户确认配对
5. Diffie-Hellman 密钥交换
6. 保存信任设备到钥匙串

### 2. WiFi 同步通道

#### TCP 服务器/客户端
- **协议**: 自定义 TCP 协议
- **端口**: 8888（可配置）
- **序列化**: Protocol Buffers
- **特性**:
  - 分片传输（支持大文件）
  - 断点续传
  - 进度回调
  - 心跳保活

#### 增量同步策略
```swift
struct SyncRequest {
    string device_id = 1;
    int64 last_sync_time = 2;       // 增量同步时间戳
    repeated string requested_ids = 3;
}

struct SyncResponse {
    repeated ClipboardItem items = 1;
    bool has_more = 2;
    int64 server_time = 3;
}
```

### 3. 蓝牙同步通道

#### macOS/iOS: MultipeerConnectivity
- **服务类型**: `clipboard-sync`
- **发现方式**: 自动发现附近的设备
- **数据传输**: MCSession.sendData
- **限制**: 单次传输 < 100KB

#### Android: BLE (Bluetooth Low Energy)
- **GATT 服务**: 自定义 UUID
- **特征**: 写入特征（接收数据）
- **广播**: AdvertiseData 包含设备信息
- **分片**: MTU 限制，分片传输

### 4. 智能通道切换

```swift
func selectChannel(for item: ClipboardItem) -> Channel {
    // 文本 → 蓝牙（快速）
    if item.type == .text && bluetoothAvailable {
        return .bluetooth
    }

    // 小图片 < 100KB → 蓝牙
    if item.thumbnailData?.count ?? 0 < 100_000 && bluetoothAvailable {
        return .bluetooth
    }

    // 大图片、历史记录 → WiFi
    if wifiAvailable {
        return .wifi
    }

    return .none
}
```

### 5. 冲突解决

```swift
enum ConflictResolutionStrategy {
    case lastWriteWins       // 最后写入优先（基于时间戳）
    case sourcePriority      // 源设备优先
    case manualResolution    // 手动解决
    case merge              // 智能合并（仅文本）
}
```

---

## 安全性设计

### 数据加密
- **算法**: AES-256-GCM
- **密钥派生**: HKDF 从共享密钥派生
- **范围**: 端到端加密，数据在传输过程中始终加密

### 设备认证
- **签名算法**: Ed25519
- **密钥管理**: 存储在钥匙串/KeyStore
- **重放保护**: 时间戳验证（60 秒窗口）

### 敏感数据保护
- **自动检测**: 识别信用卡号、邮箱、密码
- **用户配置**: 可选择不同步敏感数据
- **本地标记**: 敏感数据标记但不上传

---

## Protobuf 定义

```protobuf
syntax = "proto3";

message ClipboardItem {
  string id = 1;
  string content = 2;
  ClipboardType type = 3;
  int64 created_at = 4;
  bytes thumbnail_data = 5;
  string image_path = 6;
  string device_id = 7;
  int32 version = 8;
  bytes checksum = 9;
}

enum ClipboardType {
  TEXT = 0;
  IMAGE = 1;
  FILE = 2;
}

message SyncRequest {
  string device_id = 1;
  int64 last_sync_time = 2;
  repeated string requested_ids = 3;
}

message SyncResponse {
  repeated ClipboardItem items = 1;
  bool has_more = 2;
  int64 server_time = 3;
}

message SyncPacket {
  MessageType type = 1;
  bytes payload = 2;
  uint32 sequence_id = 3;
  uint32 total_packets = 4;
  uint32 packet_index = 5;
  string checksum = 6;
}

enum MessageType {
  SYNC_REQUEST = 0;
  SYNC_RESPONSE = 1;
  CLIPBOARD_ITEM = 2;
  HEARTBEAT = 3;
}
```

---

## 实现路线图

### 阶段一：基础设施（4-6 周）
- macOS/iOS 共享代码库
- Android 项目初始化
- Protobuf 定义
- 数据模型扩展
- 单元测试

### 阶段二：设备发现与配对（3-4 周）
- mDNS 服务实现
- BLE 广播实现
- 配对流程 UI
- 信任管理

### 阶段三：WiFi 同步通道（4-5 周）
- TCP 服务器/客户端
- 协议实现
- 增量同步
- 进度反馈

### 阶段四：蓝牙同步通道（3-4 周）
- MultipeerConnectivity 实现
- Android BLE 实现
- 实时推送
- 小文件优化

### 阶段五：智能通道切换（2-3 周）
- 通道选择器
- 网络质量检测
- 自动切换逻辑

### 阶段六：安全性增强（2-3 周）
- 端到端加密
- 设备认证
- 敏感数据保护

### 阶段七：测试与优化（3-4 周）
- 功能测试
- 性能测试
- 兼容性测试
- Bug 修复

### 阶段八：发布与维护（持续）
- App Store 发布
- Google Play 发布
- 用户反馈
- 迭代优化

**预计总工期**: 22-30 周（5.5-7.5 个月）

---

## 关键文件清单

### 需要修改的现有文件

1. `Clipboard/Models/ClipboardItem.swift` - 添加 SyncMetadata
2. `Clipboard/Services/DatabaseService.swift` - 添加同步查询方法
3. `Clipboard/Services/ClipboardMonitorService.swift` - 触发同步
4. `Clipboard/ViewModels/ClipboardHistoryViewModel.swift` - 显示同步状态

### 需要新建的文件

5. `Clipboard/Services/SyncManager.swift` - 同步核心逻辑
6. `Clipboard/Services/WiFiSyncChannel.swift` - WiFi 同步实现
7. `Clipboard/Services/BluetoothChannel.swift` - 蓝牙同步实现
8. `Clipboard/Services/DeviceManager.swift` - 设备管理
9. `Clipboard/Models/Protobuf/clipboard_sync.proto` - Protobuf 定义

---

## 风险与缓解

| 风险 | 影响 | 概率 | 缓解方案 |
|------|------|------|----------|
| 网络不稳定 | 高 | 中 | 断点续传、重试机制 |
| 蓝牙兼容性 | 中 | 中 | 测试多设备、提供降级方案 |
| 冲突解决复杂度 | 中 | 低 | 简化策略（默认 LWW） |
| 跨平台代码共享 | 高 | 低 | 严格抽象、使用 SPM |
| 用户配对体验 | 中 | 中 | 简化流程、详细引导 |

---

## 成功指标

- ✅ 设备发现率 > 95%（同一网络）
- ✅ 配对成功率 > 90%
- ✅ 同步成功率 > 99%
- ✅ 同步延迟 < 1 秒（文本，蓝牙）
- ✅ 同步延迟 < 5 秒（1MB 文件，WiFi）
- ✅ 冲突自动解决率 > 95%
- ✅ 用户评分 > 4.5/5

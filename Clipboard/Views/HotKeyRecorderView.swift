import SwiftUI
import AppKit
import Carbon

/// 快捷键录制控件
struct HotKeyRecorderView: View {
    @State private var currentModifiers: UInt32 = 0
    @State private var currentKeyCode: UInt32 = 0
    @State private var isFocused = false
    @State private var eventMonitor: Any?

    let currentHotKey: HotKeyDefinition
    @Binding var isRecording: Bool
    let onHotKeyRecorded: (HotKeyDefinition) -> Void

    init(currentHotKey: HotKeyDefinition, isRecording: Binding<Bool>, onHotKeyRecorded: @escaping (HotKeyDefinition) -> Void) {
        self.currentHotKey = currentHotKey
        self._isRecording = isRecording
        self.onHotKeyRecorded = onHotKeyRecorded
    }

    var body: some View {
        HStack(spacing: 12) {
            // 快捷键显示区域
            Text(displayText)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .frame(minWidth: 150)
                .onTapGesture {
                    toggleRecording()
                }
                .focusable()
                .onChange(of: isRecording) { _, newValue in
                    if newValue {
                        startRecordingInternal()
                    } else {
                        stopRecordingInternal()
                    }
                }

            // 录制按钮
            Button(action: {
                toggleRecording()
            }) {
                Image(systemName: isRecording ? "xmark.circle.fill" : "record.circle")
                    .font(.system(size: 20))
                    .foregroundColor(isRecording ? .red : .gray)
            }
            .buttonStyle(.plain)
            .help(isRecording ? "取消录制 (Escape)" : "录制快捷键")
        }
        .onAppear {
            print("✅ HotKeyRecorderView appeared")
        }
        .onDisappear {
            stopRecordingInternal()
        }
    }

    private var displayText: String {
        if isRecording {
            if currentKeyCode != 0 {
                return hotKeyDisplayString(keyCode: currentKeyCode, modifiers: currentModifiers)
            } else if currentModifiers != 0 {
                return modifierDisplayString(modifiers: currentModifiers)
            }
            return "按下快捷键..."
        }
        return currentHotKey.displayName
    }

    private func toggleRecording() {
        isRecording.toggle()
    }

    private func startRecordingInternal() {
        print("🎬 开始录制快捷键")
        currentModifiers = 0
        currentKeyCode = 0
        setupEventMonitor()
    }

    private func stopRecordingInternal() {
        print("⏹ 停止录制快捷键")
        removeEventMonitor()
        currentModifiers = 0
        currentKeyCode = 0
    }

    private func setupEventMonitor() {
        // 先移除旧的监听器
        removeEventMonitor()

        // 使用全局监听器捕获所有键盘事件
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .keyUp]) { event in
            self.handleKeyEvent(event)
            return nil // 消费所有事件
        }

        print("✅ 事件监听器已设置")
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            print("❌ 事件监听器已移除")
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }

        switch event.type {
        case .keyDown:
            handleKeyDown(event)
        case .flagsChanged:
            handleFlagsChanged(event)
        case .keyUp:
            handleKeyUp(event)
        default:
            break
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)

        // Escape 取消录制
        if keyCode == UInt32(kVK_Escape) {
            print("⎋ 按下 Escape，取消录制")
            isRecording = false
            return
        }

        // 记录按键
        currentKeyCode = keyCode
        print("⌨️ 按键: keyCode=\(keyCode), char=\(keyCodeToString(keyCode) ?? "?")")
    }

    private func handleKeyUp(_ event: NSEvent) {
        // 键释放时完成录制（如果有有效的按键和修饰键）
        if currentKeyCode != 0 && currentModifiers != 0 {
            print("✅ 完成录制: keyCode=\(currentKeyCode), modifiers=\(currentModifiers)")
            finishRecording()
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // 直接获取修饰键标志
        let flags = event.modifierFlags

        // 只保留我们关心的修饰键
        var modifiers: UInt32 = 0
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        currentModifiers = modifiers

        let modifierNames = modifierDisplayString(modifiers: modifiers)
        print("⌨️ 修饰键: \(modifierNames)")
    }

    private func finishRecording() {
        guard currentKeyCode != 0 else {
            isRecording = false
            return
        }

        let hotKey = HotKeyDefinition(
            keyCode: currentKeyCode,
            modifiers: currentModifiers,
            displayName: hotKeyDisplayString(keyCode: currentKeyCode, modifiers: currentModifiers)
        )

        print("✅ 快捷键已录制: \(hotKey.displayName)")

        // 调用回调
        onHotKeyRecorded(hotKey)

        // 停止录制
        isRecording = false
    }

    // MARK: - Display String Helpers

    private func hotKeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var components: [String] = []

        // 添加修饰键（⌘ 优先显示在最前面）
        if modifiers & UInt32(cmdKey) != 0 {
            components.append("⌘")
        }
        if modifiers & UInt32(controlKey) != 0 {
            components.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            components.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            components.append("⇧")
        }

        // 添加字符键
        if let charName = keyCodeToString(keyCode) {
            components.append(charName)
        }

        return components.joined()
    }

    private func modifierDisplayString(modifiers: UInt32) -> String {
        var components: [String] = []

        if modifiers & UInt32(shiftKey) != 0 {
            components.append("⇧")
        }
        if modifiers & UInt32(controlKey) != 0 {
            components.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            components.append("⌥")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            components.append("⌘")
        }

        return components.joined() + "..."
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        // 常用按键映射
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Tab: return "Tab"
        case kVK_Return: return "Return"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        // F9-F12 在某些 macOS 版本上不可用，使用硬编码值
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return "Key(\(Int(keyCode)))"
        }
    }
}

#Preview {
    HotKeyRecorderView(
        currentHotKey: .controlCommandV,
        isRecording: .constant(false),
        onHotKeyRecorded: { hotKey in
            print("录制完成: \(hotKey.displayName)")
        }
    )
    .padding()
}

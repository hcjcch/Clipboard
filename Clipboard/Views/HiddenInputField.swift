//
//  HiddenInputField.swift
//  Clipboard
//
//  隐藏输入框 - 用于接收输入法确认后的文本
//

import SwiftUI
import AppKit

struct HiddenInputField: NSViewRepresentable {
    @Binding var text: String
    var onTextChanged: ((String) -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.textColor = .clear
        textField.delegate = context.coordinator

        // 隐藏但保持可交互
        textField.frame = NSRect(x: 0, y: 0, width: 1, height: 1)

        context.coordinator.textField = textField

        // 延迟获取焦点，确保窗口已经显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // 只处理外部清空的情况
        if context.coordinator.shouldClear {
            nsView.stringValue = ""
            context.coordinator.shouldClear = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onTextChanged: onTextChanged)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onTextChanged: ((String) -> Void)?
        var shouldClear = false
        weak var textField: NSTextField?

        init(text: Binding<String>, onTextChanged: ((String) -> Void)?) {
            self._text = text
            self.onTextChanged = onTextChanged
            super.init()

            setupNotifications()
        }

        private func setupNotifications() {
            // 监听清空通知
            NotificationCenter.default.addObserver(
                forName: .init("ClearHiddenInputField"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self = self else { return }
                    self.shouldClear = true
                    self.text = ""
                }
            }

            // 监听窗口获得焦点通知
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self = self,
                          self.textField?.window?.isKeyWindow == true else { return }
                    // 窗口获得焦点时，延迟设置 textField 焦点
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.textField?.becomeFirstResponder()
                    }
                }
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }

            let newText = textField.stringValue

            // 只在文本真正改变时更新 binding
            if newText != text {
                text = newText
                onTextChanged?(newText)
            }
        }
    }
}

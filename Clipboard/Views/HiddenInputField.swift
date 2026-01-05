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

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        // 确保始终保持焦点
        DispatchQueue.main.async {
            if nsView.window?.isKeyWindow == true {
                nsView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onTextChanged: onTextChanged)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onTextChanged: ((String) -> Void)?

        init(text: Binding<String>, onTextChanged: ((String) -> Void)?) {
            self._text = text
            self.onTextChanged = onTextChanged
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }

            // 使用 textField 的字符串，这是输入法确认后的文本
            let newText = textField.stringValue

            // 只在文本真正改变时更新
            if newText != text {
                text = newText
                onTextChanged?(newText)
            }
        }
    }
}

//
//  ClipboardItemType.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Foundation

enum ClipboardItemType: String, Codable {
    case text
    case image
    case file

    /// 对应的 NSPasteboard.PasteboardType
    var pasteboardTypes: [NSPasteboard.PasteboardType] {
        switch self {
        case .text:
            return [.string]
        case .image:
            return [.png, .tiff]
        case .file:
            return [.fileURL]
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .text:
            return "文本"
        case .image:
            return "图片"
        case .file:
            return "文件"
        }
    }

    /// 图标名称 (SF Symbol)
    var iconName: String {
        switch self {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .file:
            return "doc"
        }
    }
}

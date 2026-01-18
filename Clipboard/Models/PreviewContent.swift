//
//  PreviewContent.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import AppKit
import Foundation

/// 封装预览内容和 UI 状态，用于视图绑定
struct PreviewContent: Equatable {
    /// 原始剪贴板项数据
    let item: ClipboardItem
    /// 高亮显示的文本内容（仅文本类型）
    let displayText: AttributedString?
    /// 图片缩略图数据（仅图片类型）
    let thumbnailData: Data?
    /// 文件信息（仅文件引用类型）
    let fileInfo: FileInfo?
    /// 是否正在加载内容
    let isLoading: Bool
    /// 错误消息（如有）
    let errorMessage: String?

    /// 文件信息结构体
    struct FileInfo: Equatable {
        /// 文件名
        let fileName: String
        /// 文件类型
        let fileType: String
        /// 文件数量
        let fileCount: Int
        /// 文件图标
        let fileIcon: NSImage?
    }

    /// 内容类型
    var contentType: ClipboardItemType {
        item.type
    }

    /// 是否有有效内容
    var hasValidContent: Bool {
        errorMessage == nil && !isLoading
    }

    /// 创建文本预览内容
    static func text(item: ClipboardItem, displayText: AttributedString? = nil) -> PreviewContent {
        PreviewContent(
            item: item,
            displayText: displayText,
            thumbnailData: nil,
            fileInfo: nil,
            isLoading: false,
            errorMessage: nil
        )
    }

    /// 创建图片预览内容
    static func image(item: ClipboardItem, thumbnailData: Data? = nil) -> PreviewContent {
        PreviewContent(
            item: item,
            displayText: nil,
            thumbnailData: thumbnailData,
            fileInfo: nil,
            isLoading: false,
            errorMessage: nil
        )
    }

    /// 创建文件预览内容
    static func file(item: ClipboardItem, fileInfo: FileInfo? = nil) -> PreviewContent {
        PreviewContent(
            item: item,
            displayText: nil,
            thumbnailData: nil,
            fileInfo: fileInfo,
            isLoading: false,
            errorMessage: nil
        )
    }

    /// 创建加载状态
    static func loading(item: ClipboardItem) -> PreviewContent {
        PreviewContent(
            item: item,
            displayText: nil,
            thumbnailData: nil,
            fileInfo: nil,
            isLoading: true,
            errorMessage: nil
        )
    }

    /// 创建错误状态
    static func error(item: ClipboardItem, message: String) -> PreviewContent {
        PreviewContent(
            item: item,
            displayText: nil,
            thumbnailData: nil,
            fileInfo: nil,
            isLoading: false,
            errorMessage: message
        )
    }
}

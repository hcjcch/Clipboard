//
//  ClipboardItem.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Foundation

/// 剪贴板项数据模型
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let type: ClipboardItemType
    let createdAt: Date
    var thumbnailData: Data?
    var imagePath: String?  // 图片文件 ID（不含扩展名）
    var isPinned: Bool

    init(content: String, type: ClipboardItemType, thumbnailData: Data? = nil, imagePath: String? = nil, isPinned: Bool = false) {
        self.id = UUID().uuidString
        self.content = content
        self.type = type
        self.createdAt = Date()
        self.thumbnailData = thumbnailData
        self.imagePath = imagePath
        self.isPinned = isPinned
    }

    /// 完整初始化器（用于从数据库恢复）
    init(id: String, content: String, type: ClipboardItemType, createdAt: Date, thumbnailData: Data? = nil, imagePath: String? = nil, isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.thumbnailData = thumbnailData
        self.imagePath = imagePath
        self.isPinned = isPinned
    }

    /// 从 NSPasteboard 创建 ClipboardItem
    @MainActor
    static func from(pasteboard: NSPasteboard) async -> ClipboardItem? {
        // 优先检查文件（因为文件剪贴板通常也包含文本）
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !fileURLs.isEmpty,
           let firstURL = fileURLs.first {
            // 检查是否为图片文件
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp", "heic", "heif"]
            let fileExtension = firstURL.pathExtension.lowercased()
            let isImageFile = imageExtensions.contains(fileExtension)

            // 如果是图片文件，生成缩略图
            var thumbnailData: Data?
            if isImageFile {
                thumbnailData = await generateThumbnail(for: firstURL)
            }

            return ClipboardItem(
                content: firstURL.path,
                type: .file,
                thumbnailData: thumbnailData
            )
        }

        // 检查图片（因为图片剪贴板通常也包含文本）
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            // 保存图片到文件
            let imageId = await ImageStorageService.shared.saveImage(imageData)
            let thumbnailData = await ImageStorageService.shared.generateThumbnail(from: imageData, maxSize: 240)

            return ClipboardItem(
                content: "<image>",
                type: .image,
                thumbnailData: thumbnailData ?? imageData,
                imagePath: imageId         // 文件路径用于持久化
            )
        }

        // 检查文本
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            return ClipboardItem(content: string, type: .text)
        }

        return nil
    }

    /// 从 NSPasteboard 创建 ClipboardItem（同步版本，用于兼容）
    static func from(pasteboard: NSPasteboard) -> ClipboardItem? {
        // 优先检查文件
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !fileURLs.isEmpty,
           let firstURL = fileURLs.first {
            return ClipboardItem(
                content: firstURL.path,
                type: .file,
                thumbnailData: nil
            )
        }

        // 检查图片
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            return ClipboardItem(
                content: "<image>",
                type: .image,
                thumbnailData: imageData
            )
        }

        // 检查文本
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            return ClipboardItem(content: string, type: .text)
        }

        return nil
    }

    /// 生成图片文件的缩略图
    private static func generateThumbnail(for fileURL: URL) async -> Data? {
        return await ImageStorageService.shared.generateThumbnail(from: fileURL)
    }

    /// 获取预览文本（用于显示）
    var previewText: String {
        switch type {
        case .text:
            return content.prefix(200).description
        case .image:
            return "[图片]"
        case .file:
            return URL(fileURLWithPath: content).lastPathComponent
        }
    }

    /// 比较内容是否相同（用于去重）
    func isContentEqual(to other: ClipboardItem) -> Bool {
        // 类型不同，肯定不相等
        guard type == other.type else {
            return false
        }

        switch type {
        case .text:
            // 文本比较内容字符串
            return content == other.content
        case .image:
            // 图片比较实际数据
            guard let data1 = thumbnailData, let data2 = other.thumbnailData else {
                return false
            }
            return data1 == data2
        case .file:
            // 文件比较路径
            return content == other.content
        }
    }
}

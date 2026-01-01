//
//  ImageStorageService.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Foundation

/// 图片存储服务
actor ImageStorageService {
    static let shared = ImageStorageService()

    private let imagesDirectory: URL
    private let thumbnailsDirectory: URL

    private init() {
        // 获取应用支持目录
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("无法获取应用支持目录")
        }

        // 创建图片目录
        let appDirectory = appSupportURL.appendingPathComponent("Clipboard")
        self.imagesDirectory = appDirectory.appendingPathComponent("Images")
        self.thumbnailsDirectory = appDirectory.appendingPathComponent("Thumbnails")

        // 创建目录
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)

        print("图片存储目录: \(imagesDirectory.path)")
        print("缩略图目录: \(thumbnailsDirectory.path)")
    }

    /// 保存图片到文件
    func saveImage(_ data: Data) -> String? {
        let imageId = UUID().uuidString
        let imagePath = imagesDirectory.appendingPathComponent("\(imageId).png")

        do {
            try data.write(to: imagePath)
            print("图片已保存: \(imageId)")
            return imageId
        } catch {
            print("保存图片失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 读取图片文件
    func loadImage(imageId: String) -> Data? {
        let imagePath = imagesDirectory.appendingPathComponent("\(imageId).png")
        return try? Data(contentsOf: imagePath)
    }

    /// 删除图片文件
    func deleteImage(imageId: String) {
        let imagePath = imagesDirectory.appendingPathComponent("\(imageId).png")
        try? FileManager.default.removeItem(at: imagePath)
        print("图片已删除: \(imageId)")
    }

    /// 生成缩略图（可选）
    func generateThumbnail(from imageData: Data, maxSize: CGFloat = 200) -> Data? {
        guard let nsImage = NSImage(data: imageData) else {
            return nil
        }

        // 计算缩略图尺寸（保持宽高比）
        let originalSize = nsImage.size
        let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)

        guard ratio < 1 else {
            // 图片已经够小，不需要缩放
            return imageData
        }

        let newSize = NSSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )

        // 创建缩略图
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        nsImage.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        // 转换为 PNG 数据
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        return pngData
    }

    /// 从文件 URL 生成缩略图
    func generateThumbnail(from fileURL: URL) async -> Data? {
        guard let nsImage = NSImage(contentsOf: fileURL) else {
            print("无法加载图片文件: \(fileURL.path)")
            return nil
        }

        // 使用现有的缩略图生成方法，目标尺寸 60x60
        let maxSize: CGFloat = 60

        // 计算缩略图尺寸（保持宽高比）
        let originalSize = nsImage.size
        let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)

        guard ratio > 0 else {
            return nil
        }

        let newSize = NSSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )

        // 创建缩略图
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        nsImage.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        // 转换为 PNG 数据
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        print("已生成图片文件缩略图: \(fileURL.lastPathComponent) -> \(pngData.count) bytes")
        return pngData
    }

    /// 清理所有图片（用于重置）
    func clearAllImages() {
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.removeItem(at: imagesDirectory)
            }
            if fileManager.fileExists(atPath: thumbnailsDirectory.path) {
                try fileManager.removeItem(at: thumbnailsDirectory)
            }
            
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
            
            print("所有图片已清理")
        } catch {
            print("清理图片失败: \(error.localizedDescription)")
        }
    }

    /// 获取图片文件大小（字节）
    func getImageSize(imageId: String) -> Int64? {
        let imagePath = imagesDirectory.appendingPathComponent("\(imageId).png")
        let attributes = try? FileManager.default.attributesOfItem(atPath: imagePath.path)
        return attributes?[.size] as? Int64
    }

    /// 获取存储总大小
    func getTotalStorageSize() -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }

    /// 格式化文件大小
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

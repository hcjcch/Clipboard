//
//  ClipboardMonitorService.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import AppKit
import Foundation

/// 剪贴板变化通知名称
extension Notification.Name {
    static let clipboardDidChange = Notification.Name("clipboardDidChange")
}

/// 剪贴板监听服务
@MainActor
class ClipboardMonitorService: ObservableObject {
    static let shared = ClipboardMonitorService()

    private var pasteboard: NSPasteboard
    private var changeCount: Int
    private var timer: Timer?
    private var isMonitoring = false

    // 轮询间隔（秒）
    private let pollingInterval: TimeInterval = 0.5

    private init() {
        self.pasteboard = NSPasteboard.general
        self.changeCount = pasteboard.changeCount
    }

    /// 开始监听剪贴板
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        changeCount = pasteboard.changeCount

        // 使用定时器轮询剪贴板变化
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForChanges()
            }
        }

        print("剪贴板监听已启动")
    }

    /// 停止监听剪贴板
    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        timer?.invalidate()
        timer = nil

        print("剪贴板监听已停止")
    }

    /// 检查剪贴板变化
    private func checkForChanges() async {
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != changeCount else {
            return
        }

        changeCount = currentChangeCount

        // 创建新的剪贴板项（使用异步方法）
        guard let newItem = await ClipboardItem.from(pasteboard: pasteboard) else {
            return
        }

        // 保存到数据库
        do {
            try DatabaseService.shared.insert(newItem)

            // 发送通知
            NotificationCenter.default.post(
                name: .clipboardDidChange,
                object: nil,
                userInfo: ["item": newItem]
            )

            print("检测到剪贴板变化: \(newItem.type.displayName) - \(newItem.previewText.prefix(50))")
        } catch {
            print("保存剪贴板项失败: \(error.localizedDescription)")
        }
    }

    /// 获取当前剪贴板内容
    func getCurrentContent() -> String? {
        return pasteboard.string(forType: .string)
    }

    /// 复制内容到剪贴板
    func copyToClipboard(_ item: ClipboardItem) async {
        switch item.type {
        case .text:
            pasteboard.clearContents()
            pasteboard.setString(item.content, forType: .string)
            print("已复制文本: \(item.content.prefix(50))")

        case .image:
            // 优先从文件读取，如果没有则使用 thumbnailData
            var imageData: Data?

            print("复制图片 - imagePath: \(item.imagePath?.description ?? "nil"), thumbnailData: \(item.thumbnailData?.description ?? "nil")")

            if let imageId = item.imagePath {
                imageData = await ImageStorageService.shared.loadImage(imageId: imageId)
                print("从文件加载图片: \(imageData?.count ?? 0) 字节")
            }

            if imageData == nil {
                imageData = item.thumbnailData
                print("使用 thumbnailData: \(imageData?.count ?? 0) 字节")
            }

            if let data = imageData {
                // 使用 NSPasteboardItem 设置剪贴板
                let pasteboardItem = NSPasteboardItem()
                pasteboardItem.setData(data, forType: .png)

                // 如果可能，也设置 TIFF 格式
                if let tiffData = NSImage(data: data)?.tiffRepresentation {
                    pasteboardItem.setData(tiffData, forType: .tiff)
                }

                pasteboard.clearContents()
                pasteboard.writeObjects([pasteboardItem])

                print("已复制图片到剪贴板: PNG \(data.count) 字节")
            } else {
                print("错误: 没有图片数据可复制")
            }

        case .file:
            // 复制文件到剪贴板
            let fileURL = URL(fileURLWithPath: item.content)
            pasteboard.clearContents()
            pasteboard.writeObjects([fileURL as NSURL])
            print("已复制文件: \(fileURL.lastPathComponent)")
        }

        changeCount = pasteboard.changeCount
    }

    /// 手动检查剪贴板（用于调试）
    func manualCheck() async {
        await checkForChanges()
    }
}

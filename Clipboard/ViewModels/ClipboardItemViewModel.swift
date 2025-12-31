//
//  ClipboardItemViewModel.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import Foundation

@MainActor
class ClipboardItemViewModel: ObservableObject {
    let item: ClipboardItem
    private let onDelete: () -> Void

    init(item: ClipboardItem, onDelete: @escaping () -> Void) {
        self.item = item
        self.onDelete = onDelete
    }

    /// 复制到剪贴板
    func copyToClipboard() {
        Task {
            await ClipboardMonitorService.shared.copyToClipboard(item)
        }
    }

    /// 删除项
    func delete() async {
        do {
            try await DatabaseService.shared.delete(id: item.id, imagePath: item.imagePath)
            onDelete()
            print("已删除剪贴板项: \(item.id)")
        } catch {
            print("删除失败: \(error.localizedDescription)")
        }
    }

    /// 格式化创建时间
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    /// 预览文本
    var previewText: String {
        item.previewText
    }
}

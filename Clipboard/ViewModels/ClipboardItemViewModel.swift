//
//  ClipboardItemViewModel.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import Foundation
import SwiftUI

@MainActor
class ClipboardItemViewModel: ObservableObject {
    let item: ClipboardItem
    private let onDelete: () -> Void
    let searchKeyword: String

    init(item: ClipboardItem, onDelete: @escaping () -> Void, searchKeyword: String = "") {
        self.item = item
        self.onDelete = onDelete
        self.searchKeyword = searchKeyword
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

    /// 高亮预览文本
    var highlightedPreview: AttributedString {
        TextHighlighter.highlightedPreview(
            item.content,
            keyword: searchKeyword,
            maxLength: 200
        )
    }
}

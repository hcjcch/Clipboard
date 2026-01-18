//
//  PreviewTextView.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import SwiftUI

/// 文本预览视图组件
///
/// 职责：
/// - 显示文本内容的完整预览
/// - 文本居中显示、自动换行和截断逻辑
struct PreviewTextView: View {
    /// 要预览的剪贴板项
    let item: ClipboardItem

    /// 最大行数限制
    private var maxLines: Int {
        20
    }

    /// 文本统计信息
    private var textStats: (lines: Int, chars: Int) {
        let lines = item.content.components(separatedBy: .newlines).count
        let chars = item.content.count
        return (lines, chars)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 文本内容
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(item.content)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .lineSpacing(4)
                }
                .padding(16)
            }

            Divider()

            // 底部统计信息
            HStack(spacing: 16) {
                // 行数
                HStack(spacing: 6) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text("\(textStats.lines) 行")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                // 字符数
                HStack(spacing: 6) {
                    Image(systemName: "character")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text("\(textStats.chars) 字符")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 短文本预览
        PreviewTextView(
            item: ClipboardItem(
                content: "这是一段短文本示例。",
                type: .text
            )
        )
        .frame(width: 300, height: 300)
        .background(Color.gray.opacity(0.1))

        Divider()

        // 长文本预览
        PreviewTextView(
            item: ClipboardItem(
                content: String(repeating: "这是一段很长的文本内容，用于测试预览面板的显示效果。", count: 10),
                type: .text
            )
        )
        .frame(width: 300, height: 300)
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}

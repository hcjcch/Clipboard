//
//  TextHighlighter.swift
//  Clipboard
//
//  Created by Claude on 2025/01/05.
//

import SwiftUI
import AppKit

/// 文本高亮工具
struct TextHighlighter {

    // MARK: - 高亮配置

    /// 高亮样式配置
    struct HighlightStyle {
        let backgroundColor: Color
        let foregroundColor: Color
        let fontWeight: Font.Weight

        static let `default` = HighlightStyle(
            backgroundColor: Color.yellow.opacity(0.3),
            foregroundColor: Color.primary,
            fontWeight: .medium
        )

        static let subtle = HighlightStyle(
            backgroundColor: Color.accentColor.opacity(0.15),
            foregroundColor: Color.accentColor,
            fontWeight: .medium
        )
    }

    // MARK: - 公开接口

    /// 高亮多个范围
    static func highlight(
        _ text: String,
        ranges: [Range<String.Index>],
        style: HighlightStyle = .default
    ) -> AttributedString {
        guard !ranges.isEmpty else {
            return AttributedString(text)
        }

        var attributed = AttributedString(text)

        for range in ranges {
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].backgroundColor = style.backgroundColor
                attributed[attributedRange].foregroundColor = style.foregroundColor
                attributed[attributedRange].font = .system(size: 13, weight: style.fontWeight)
            }
        }

        return attributed
    }

    /// 高亮关键词（使用 FuzzyMatcher 查找范围）
    static func highlight(
        _ text: String,
        keyword: String,
        style: HighlightStyle = .default
    ) -> AttributedString {
        guard !keyword.isEmpty else {
            return AttributedString(text)
        }

        let ranges = FuzzyMatcher.findAllMatchRanges(in: text, keyword: keyword)
        return highlight(text, ranges: ranges, style: style)
    }

    /// 为搜索结果创建高亮文本
    static func highlightedText(
        for item: ClipboardItem,
        keyword: String,
        maxLength: Int = 200
    ) -> AttributedString {
        let previewText = String(item.content.prefix(maxLength))

        guard !keyword.isEmpty else {
            return AttributedString(previewText)
        }

        // 使用模糊匹配查找所有范围
        let ranges = FuzzyMatcher.findAllMatchRanges(in: previewText, keyword: keyword)

        // 高亮显示
        return highlight(previewText, ranges: ranges, style: .subtle)
    }

    /// 获取预览文本（带高亮），如果文本过长则截断并添加省略号
    static func highlightedPreview(
        _ text: String,
        keyword: String,
        maxLength: Int = 200,
        style: HighlightStyle = .default
    ) -> AttributedString {
        let isTruncated = text.count > maxLength
        let previewText = isTruncated ? String(text.prefix(maxLength)) + "..." : text

        guard !keyword.isEmpty else {
            return AttributedString(previewText)
        }

        // 在预览文本中查找匹配
        let ranges = FuzzyMatcher.findAllMatchRanges(in: previewText, keyword: keyword)

        // 如果有匹配，高亮显示
        if !ranges.isEmpty {
            return highlight(previewText, ranges: ranges, style: style)
        }

        return AttributedString(previewText)
    }
}

// MARK: - SwiftUI View 扩展

extension View {
    /// 将高亮文本应用到 Text view
    func highlightedText(_ attributedString: AttributedString) -> some View {
        Text(attributedString)
    }
}

// MARK: - 调试工具

#if DEBUG
extension TextHighlighter {
    /// 打印高亮信息（用于调试）
    static func debugPrint(
        _ text: String,
        ranges: [Range<String.Index>]
    ) {
        print("=== 高亮调试信息 ===")
        print("原文: \(text)")
        print("匹配范围数: \(ranges.count)")

        for (index, range) in ranges.enumerated() {
            let matchedText = String(text[range])
            let offset = text.distance(from: text.startIndex, to: range.lowerBound)
            print("  [\(index)] 偏移量: \(offset), 内容: \"\(matchedText)\"")
        }

        print("==================")
    }
}
#endif

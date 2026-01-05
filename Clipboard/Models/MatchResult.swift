//
//  MatchResult.swift
//  Clipboard
//
//  Created by Claude on 2025/01/05.
//

import Foundation

/// 模糊匹配结果
struct MatchResult {
    /// 是否匹配
    let matched: Bool

    /// 匹配的范围（用于高亮）
    let ranges: [Range<String.Index>]

    /// 匹配得分（用于排序）
    let score: Double

    init(matched: Bool, ranges: [Range<String.Index>] = [], score: Double = 0.0) {
        self.matched = matched
        self.ranges = ranges
        self.score = score
    }
}

/// 匹配类型
enum MatchType {
    /// 完全匹配
    case exact
    /// 前缀匹配
    case prefix
    /// 包含匹配
    case contains
    /// 模糊匹配（关键词分离）
    case fuzzy
    /// 近似匹配（编辑距离）
    case approximate
}

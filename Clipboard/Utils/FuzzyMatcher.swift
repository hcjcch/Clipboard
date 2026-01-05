//
//  FuzzyMatcher.swift
//  Clipboard
//
//  Created by Claude on 2025/01/05.
//

import Foundation

/// 模糊匹配工具
struct FuzzyMatcher {

    // MARK: - 公开接口

    /// 模糊匹配（关键词分离 + 容错）
    static func match(_ text: String, keyword: String) -> MatchResult {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespaces)

        // 空关键词匹配所有
        guard !trimmedKeyword.isEmpty else {
            return MatchResult(matched: true, ranges: [], score: 0.0)
        }

        let keywords = trimmedKeyword.split(separator: " ")
            .map { String($0).lowercased() }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else {
            return MatchResult(matched: true, ranges: [], score: 0.0)
        }

        var ranges: [Range<String.Index>] = []
        var totalScore = 0.0
        var lastEndIndex = text.startIndex

        for keyword in keywords {
            // 使用统一的匹配策略
            guard let matchResult = findFirstMatch(in: text, keyword: keyword, from: lastEndIndex) else {
                return MatchResult(matched: false)
            }

            ranges.append(contentsOf: matchResult.ranges)
            if let lastRange = matchResult.ranges.last {
                lastEndIndex = lastRange.upperBound
            }
            totalScore += matchResult.score
        }

        // 计算最终得分（考虑匹配度、位置、连续性）
        let positionBonus = calculatePositionBonus(in: text, ranges: ranges)
        let finalScore = totalScore + positionBonus

        return MatchResult(matched: true, ranges: ranges, score: finalScore)
    }

    /// 查找所有匹配范围（用于高亮）
    static func findAllMatchRanges(in text: String, keyword: String) -> [Range<String.Index>] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmedKeyword.isEmpty else { return [] }

        let keywords = trimmedKeyword.split(separator: " ")
            .map { String($0).lowercased() }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return [] }

        var allRanges: [Range<String.Index>] = []

        for keyword in keywords {
            var searchStart = text.startIndex

            // 查找所有出现
            while searchStart < text.endIndex {
                if let matchResult = findFirstMatch(in: text, keyword: keyword, from: searchStart) {
                    allRanges.append(contentsOf: matchResult.ranges)

                    // 移动搜索位置到匹配结束后
                    if let lastRange = matchResult.ranges.last {
                        searchStart = lastRange.upperBound

                        // 完全匹配和首字母匹配的继续搜索逻辑不同
                        if matchResult.matchType == .exact {
                            // 完全匹配：从匹配结束位置继续
                            continue
                        } else {
                            // 其他匹配类型：只找到第一个，避免重复
                            break
                        }
                    }
                } else {
                    break
                }
            }
        }

        return allRanges
    }

    // MARK: - 私有方法

    /// 匹配结果类型
    private enum MatchType {
        case exact           // 完全匹配
        case acronym         // 首字母缩写
        case prefix          // 前缀匹配
        case approximate     // 近似匹配
    }

    /// 单次匹配结果
    private struct SingleMatch {
        let ranges: [Range<String.Index>]
        let score: Double
        let matchType: MatchType
    }

    /// 核心匹配逻辑：按优先级尝试 4 种策略
    /// - Returns: 第一个成功的匹配结果，失败返回 nil
    private static func findFirstMatch(
        in text: String,
        keyword: String,
        from startIndex: String.Index
    ) -> SingleMatch? {
        let lowerText = text.lowercased()
        let searchRange = startIndex..<text.endIndex

        // 策略 1: 完全匹配（最高优先级，得分 1.0）
        if let range = lowerText.range(of: keyword, range: searchRange) {
            if let originalRange = rangeInOriginalText(text, lowerRange: range) {
                return SingleMatch(ranges: [originalRange], score: 1.0, matchType: .exact)
            }
        }

        // 策略 2: 首字母缩写匹配（得分 0.9-1.0）
        if let acronymResult = findAcronymMatch(in: text, keyword: keyword, from: startIndex) {
            return SingleMatch(
                ranges: acronymResult.ranges,
                score: acronymResult.score,
                matchType: .acronym
            )
        }

        // 策略 3: 前缀匹配（得分 0.8）
        if let prefixRange = findPrefixMatch(in: text, keyword: keyword, from: startIndex) {
            return SingleMatch(ranges: [prefixRange], score: 0.8, matchType: .prefix)
        }

        // 策略 4: 近似匹配（得分 0.5）
        if let approximateRange = findApproximateMatch(
            in: text,
            keyword: keyword,
            from: startIndex,
            maxDistance: max(1, keyword.count / 3)
        ) {
            return SingleMatch(ranges: [approximateRange], score: 0.5, matchType: .approximate)
        }

        return nil // 所有策略都失败
    }

    /// 首字母缩写匹配（如 "fh" 匹配 "feature/home"）
    /// 将文本按分隔符拆分，匹配单词首字母
    private static func findAcronymMatch(
        in text: String,
        keyword: String,
        from startIndex: String.Index
    ) -> (ranges: [Range<String.Index>], score: Double)? {
        // 关键词必须是单个单词（不含空格）
        guard !keyword.contains(" ") else { return nil }

        // 将文本按分隔符拆分成单词
        let separators = CharacterSet(charactersIn: "/-_. ")
        let words = text[startIndex...]
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }

        // 快速失败：关键词字符数不能超过单词数
        guard keyword.count <= words.count else { return nil }

        var keywordChars = Array(keyword.lowercased())
        var matchedRanges: [Range<String.Index>] = []
        var currentWordIndex = 0
        var searchPosition = startIndex

        // 逐个字符匹配单词首字母
        for char in keywordChars {
            var found = false

            // 从当前单词开始查找
            for i in currentWordIndex..<words.count {
                let word = words[i]
                guard !word.isEmpty else { continue }

                // 找到这个单词在原文中的位置
                if let wordRange = text.range(
                    of: word,
                    options: .caseInsensitive,
                    range: searchPosition..<text.endIndex
                ) {
                    // 检查单词首字母是否匹配
                    let firstChar = word[word.startIndex]
                    if firstChar.lowercased() == String(char) {
                        matchedRanges.append(wordRange.lowerBound..<text.index(after: wordRange.lowerBound))
                        currentWordIndex = i + 1
                        searchPosition = wordRange.upperBound
                        found = true
                        break
                    }
                }
            }

            if !found {
                return nil // 匹配失败
            }
        }

        // 计算得分：单词跨度越小，得分越高
        let spannedWords = currentWordIndex
        let coverageScore = Double(keywordChars.count) / Double(spannedWords)
        let baseScore = 0.9 // 首字母匹配的基础得分较高

        return (matchedRanges, baseScore + coverageScore * 0.1)
    }

    /// 在原始文本中找到对应范围
    private static func rangeInOriginalText(
        _ text: String,
        lowerRange: Range<String.Index>
    ) -> Range<String.Index>? {
        let lowerText = text.lowercased()
        let lowerStart = lowerRange.lowerBound
        let lowerEnd = lowerRange.upperBound

        // 计算在 lowercased 文本中的偏移量
        let startOffset = lowerText.distance(from: lowerText.startIndex, to: lowerStart)
        let endOffset = lowerText.distance(from: lowerText.startIndex, to: lowerEnd)

        // 在原始文本中找到对应位置
        let originalStart = text.index(text.startIndex, offsetBy: startOffset)
        let originalEnd = text.index(text.startIndex, offsetBy: endOffset)

        return originalStart..<originalEnd
    }

    /// 查找前缀匹配
    private static func findPrefixMatch(
        in text: String,
        keyword: String,
        from startIndex: String.Index
    ) -> Range<String.Index>? {
        guard keyword.count >= 2 else { return nil }

        let words = text[startIndex...].components(separatedBy: .whitespacesAndNewlines)

        for word in words {
            if word.lowercased().hasPrefix(keyword) {
                if let range = text.range(of: word, options: .caseInsensitive) {
                    return range
                }
            }
        }

        return nil
    }

    /// 近似匹配（编辑距离）
    private static func findApproximateMatch(
        in text: String,
        keyword: String,
        from startIndex: String.Index,
        maxDistance: Int
    ) -> Range<String.Index>? {
        let substring = String(text[startIndex...])
        let words = substring.components(separatedBy: .whitespacesAndNewlines)

        for word in words {
            let distance = levenshteinDistance(word.lowercased(), keyword)
            if distance <= maxDistance {
                if let range = text.range(of: word, options: .caseInsensitive) {
                    return range
                }
            }
        }

        return nil
    }

    /// 计算编辑距离（Levenshtein Distance）
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let s1Count = s1Array.count
        let s2Count = s2Array.count

        // 边界情况：任一字符串为空
        if s1Count == 0 { return s2Count }
        if s2Count == 0 { return s1Count }

        var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)

        for i in 0...s1Count {
            matrix[i][0] = i
        }

        for j in 0...s2Count {
            matrix[0][j] = j
        }

        for i in 1...s1Count {
            for j in 1...s2Count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // 删除
                    matrix[i][j - 1] + 1,      // 插入
                    matrix[i - 1][j - 1] + cost // 替换
                )
            }
        }

        return matrix[s1Count][s2Count]
    }

    /// 计算位置奖励（匹配越靠前，得分越高）
    private static func calculatePositionBonus(
        in text: String,
        ranges: [Range<String.Index>]
    ) -> Double {
        guard !ranges.isEmpty else { return 0.0 }

        let firstMatchOffset = text.distance(from: text.startIndex, to: ranges[0].lowerBound)
        let textLength = text.count

        // 如果匹配在文本前 20%，给予奖励
        if firstMatchOffset < textLength / 5 {
            return 0.5
        } else if firstMatchOffset < textLength / 2 {
            return 0.2
        }

        return 0.0
    }
}

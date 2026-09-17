//
//  ClipboardTests.swift
//  ClipboardTests
//
//  Created by huangchen.102 on 2025/12/30.
//

import Testing
@testable import Clipboard

struct ClipboardTests {

    @Test func fuzzyMatcherPreservesMatchingStrategies() {
        #expect(FuzzyMatcher.match("feature/home", keyword: "fh").matched)
        #expect(FuzzyMatcher.match("clipboard history", keyword: "clip hist").matched)
        #expect(FuzzyMatcher.match("performance", keyword: "performnce").matched)
    }

    @Test func fuzzyMatcherRejectsUnrelatedContent() {
        let result = FuzzyMatcher.match(
            "a large clipboard history item",
            keyword: "completely-unrelated"
        )

        #expect(!result.matched)
    }

    @Test func fuzzyMatcherHandlesLargeNonMatchingContent() {
        let content = Array(
            repeating: "substantially-long-unrelated-token",
            count: 5_000
        ).joined(separator: " ")

        let result = FuzzyMatcher.match(content, keyword: "xyz")

        #expect(!result.matched)
    }

}

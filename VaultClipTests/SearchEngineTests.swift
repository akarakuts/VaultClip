//
// SearchIndexTests — folded ranking, diacritics, password secrecy (T22).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class SearchIndexTests: XCTestCase {

    func testHelloMatchesSayHelloCaseInsensitive() {
        XCTAssertGreaterThan(
            SearchRanker.score(
                query: SearchFold.fold("hello"),
                tokens: [SearchFold.fold("hello")],
                haystack: SearchFold.fold("Say Hello")
            ),
            0
        )
    }

    func testCafeMatchesCafeWithAccent() {
        XCTAssertGreaterThan(
            SearchRanker.score(
                query: SearchFold.fold("cafe"),
                tokens: [SearchFold.fold("cafe")],
                haystack: SearchFold.fold("Café")
            ),
            0
        )
    }

    func testShortQueryDoesNotMatchScatteredLettersInHugeHaystack() {
        let huge = String(repeating: "x", count: 25_000) + "a" + String(repeating: "y", count: 25_000) + "b"
            + String(repeating: "z", count: 1000) + "c"
        let folded = SearchFold.fold(huge)
        let query = SearchFold.fold("abc")
        XCTAssertEqual(
            SearchRanker.score(query: query, tokens: [query], haystack: folded),
            0,
            "50 KB text must not match a 3-letter fuzzy subsequence"
        )
    }

    func testRankingPrefersWordStartOverLooseTokenMatch() {
        let query = SearchFold.fold("vault")
        let tokens = [query]
        let prefix = SearchRanker.score(query: query, tokens: tokens, haystack: SearchFold.fold("vault manager"))
        let embedded = SearchRanker.score(query: query, tokens: tokens, haystack: SearchFold.fold("myvault tool"))
        XCTAssertGreaterThan(prefix, embedded)
    }

    func testPasswordSecretValueIsNotInSearchableText() {
        let secret = "super-secret-password-value"
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let item = HistoryItem(
            unsavedData: [.string: secret.data(using: .utf8)!],
            cache: cache,
            isPassword: true,
            passwordComment: "GitHub",
            passwordLogin: "alice",
            passwordURL: "https://github.com/login"
        )
        let source = SearchSource(item: item)
        let done = expectation(description: "bg searchableText")
        DispatchQueue.global(qos: .userInitiated).async {
            let text = HistoryItemText.searchableText(for: source, cache: cache)
            XCTAssertFalse(text.contains(secret))
            XCTAssertTrue(text.contains("GitHub"))
            XCTAssertTrue(text.lowercased().contains("github.com"))
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
    }

    func testSearchIndexReturnsRankedIdsOffMain() {
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let older = HistoryItem(
            unsavedData: [.string: "Say Hello world".data(using: .utf8)!],
            cache: cache,
            copiedAt: Date(timeIntervalSince1970: 1)
        )
        let newer = HistoryItem(
            unsavedData: [.string: "hello".data(using: .utf8)!],
            cache: cache,
            copiedAt: Date(timeIntervalSince1970: 100)
        )
        let index = SearchIndex()
        let built = expectation(description: "built")
        let searched = expectation(description: "searched")
        let sources = [SearchSource(item: older), SearchSource(item: newer)]
        index.replaceAll(sources: sources, cache: cache) {
            built.fulfill()
            index.search(
                query: "hello",
                visibleIds: [older.fsId, newer.fsId],
                copiedAt: [older.fsId: older.copiedAt, newer.fsId: newer.copiedAt]
            ) { ids in
                XCTAssertEqual(ids.first, newer.fsId, "exact/fresher hello should rank first")
                XCTAssertTrue(ids.contains(older.fsId))
                searched.fulfill()
            }
        }
        wait(for: [built, searched], timeout: 5)
    }
}

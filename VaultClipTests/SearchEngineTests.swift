//
//  SearchEngineTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class SearchEngineTests: XCTestCase {
    
    func testSearchReturnsHistoryIndicesWhenEarlierItemsAreNotSearchable() {
        // Simulates: [image, "hello", image, "world"] — only indices 1 and 3 are searchable.
        let engine = SearchEngine(
            data: ["hello there", "the world"],
            historyIndices: [1, 3]
        )
        
        let hello = expectation(description: "hello match")
        engine.search(query: "hello") { result in
            XCTAssertEqual(result.results, [1])
            hello.fulfill()
        }
        
        let world = expectation(description: "world match")
        engine.search(query: "world") { result in
            XCTAssertEqual(result.results, [3])
            world.fulfill()
        }
        
        wait(for: [hello, world], timeout: 5)
    }
    
    func testPerformSearchIsCaseInsensitiveSubsequence() {
        XCTAssertTrue(performSearch(needle: "fb", haystack: "Foo Bar"))
        XCTAssertFalse(performSearch(needle: "baz", haystack: "Foo Bar"))
    }
    
    func testSearchIncludesPasswordURL() {
        let item = HistoryItem(
            unsavedData: [.string: "secret".data(using: .utf8)!],
            cache: HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000),
            isPassword: true,
            passwordComment: "GitHub",
            passwordLogin: "alice",
            passwordURL: "https://github.com/login"
        )
        let engine = SearchEngine(historyItems: [item])
        let match = expectation(description: "url match")
        engine.search(query: "github.com") { result in
            XCTAssertEqual(result.results, [0])
            match.fulfill()
        }
        wait(for: [match], timeout: 5)
    }

    func testDuplicateSearchesInFlightShareResultInstance() {
        let itemCount = 1_000
        let engine = SearchEngine(
            data: Array(repeating: "alpha beta", count: itemCount),
            historyIndices: Array(0..<itemCount)
        )
        var firstResult: SearchResult?
        var secondResult: SearchResult?
        let first = expectation(description: "first search")
        let second = expectation(description: "second search")

        engine.search(query: "alpha") { result in
            firstResult = result
            first.fulfill()
        }
        engine.search(query: "alpha") { result in
            secondResult = result
            second.fulfill()
        }

        wait(for: [first, second], timeout: 5)
        XCTAssertTrue(firstResult === secondResult)
    }
}

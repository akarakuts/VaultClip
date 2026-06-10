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
}

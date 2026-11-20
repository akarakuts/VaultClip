//
// PasswordURLTests — only http(s) password links are openable (T11).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PasswordURLTests: XCTestCase {

    func testHTTPSIsOpenable() {
        let url = HistoryItem.openableHTTPURL(from: "https://a.b")
        XCTAssertEqual(url?.absoluteString, "https://a.b")
    }

    func testFileURLRejected() {
        XCTAssertNil(HistoryItem.openableHTTPURL(from: "file:///Applications/Calculator.app"))
    }

    func testBareHostGetsHTTPS() {
        XCTAssertEqual(
            HistoryItem.openableHTTPURL(from: "example.com")?.absoluteString,
            "https://example.com"
        )
    }
}

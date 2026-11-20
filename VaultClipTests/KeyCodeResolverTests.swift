//
// KeyCodeResolverTests — QWERTY/Dvorak tables for character → keycode (T19).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class KeyCodeResolverTests: XCTestCase {

    func testQWERTYMapsVToNine() {
        // Minimal QWERTY-like table: only code 9 produces "v".
        let table: [UInt16: String] = [9: "v", 0: "a", 1: "s"]
        let code = KeyCodeResolver.keyCode(for: "v") { table[$0] }
        XCTAssertEqual(code, 9)
    }

    func testDvorakMapsVToFortySeven() {
        // Dvorak places "v" on keycode 47.
        let table: [UInt16: String] = [47: "v", 9: ".", 0: "a"]
        let code = KeyCodeResolver.keyCode(for: "v") { table[$0] }
        XCTAssertEqual(code, 47)
    }

    func testMissingCharacterReturnsNil() {
        let code = KeyCodeResolver.keyCode(for: "v") { _ in "x" }
        XCTAssertNil(code)
    }
}

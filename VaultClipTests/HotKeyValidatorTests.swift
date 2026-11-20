//
// HotKeyValidatorTests — allowed vs forbidden toggle shortcuts (T27).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
import HotKey
@testable import VaultClip

final class HotKeyValidatorTests: XCTestCase {
    func testAllowsCommandShiftV() {
        XCTAssertNoThrow(try HotKeyValidator.validate(key: .v, modifiers: [.command, .shift]).get())
    }

    func testAllowsBareFunctionKey() {
        XCTAssertNoThrow(try HotKeyValidator.validate(key: .f5, modifiers: []).get())
    }

    func testRejectsCommandC() {
        XCTAssertEqual(HotKeyValidator.validate(key: .c, modifiers: [.command]), .failure(.systemShortcut))
    }

    func testRejectsShiftOnlyLetter() {
        XCTAssertEqual(HotKeyValidator.validate(key: .a, modifiers: [.shift]), .failure(.needsModifier))
    }

    func testRejectsControlSpace() {
        // Reserved both as a system shortcut and a panel-scoped key.
        XCTAssertEqual(HotKeyValidator.validate(key: .space, modifiers: [.control]), .failure(.systemShortcut))
    }

    func testRejectsCommandDigitPanelConflict() {
        XCTAssertEqual(HotKeyValidator.validate(key: .one, modifiers: [.command]), .failure(.panelConflict))
    }

    func testQuoteTitleIsApostrophe() {
        XCTAssertEqual(Key.quote.title, "'")
    }
}

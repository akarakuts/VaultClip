//
// ExcludedAppsPolicyTests — user denylist merges with built-in policy (T33).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ExcludedAppsPolicyTests: XCTestCase {
    func testUserDenylistIsHonored() {
        XCTAssertTrue(
            HistoryPasteboardPolicy.shouldIgnoreSource(
                bundleId: "com.example.secret",
                userDenylist: ["com.example.secret"]
            )
        )
        XCTAssertFalse(
            HistoryPasteboardPolicy.shouldIgnoreSource(
                bundleId: "com.example.ok",
                userDenylist: ["com.example.secret"]
            )
        )
    }
}

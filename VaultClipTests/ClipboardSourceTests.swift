//
// ClipboardSourceTests — frontmost-vs-tracked resolution for copy origin.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ClipboardSourceTests: XCTestCase {

    func testWhenFrontmostIsSelfReturnsTracked() {
        let tracked = "com.apple.Safari"
        XCTAssertEqual(
            ClipboardSource.resolve(frontmost: AppIdentity.bundleIdentifier, tracked: tracked),
            tracked
        )
    }

    func testWhenFrontmostIsOtherReturnsFrontmost() {
        XCTAssertEqual(
            ClipboardSource.resolve(frontmost: "com.apple.Safari", tracked: "com.apple.Notes"),
            "com.apple.Safari"
        )
    }

    func testWhenFrontmostNilFallsBackToTracked() {
        XCTAssertEqual(
            ClipboardSource.resolve(frontmost: nil, tracked: "com.apple.Notes"),
            "com.apple.Notes"
        )
    }
}

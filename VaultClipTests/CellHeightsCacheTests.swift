//
// CellHeightsCacheTests — distinct display signatures coexist (T24).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class CellHeightsCacheTests: XCTestCase {
    func testDifferentDisplaySignaturesKeepSeparateHeights() {
        let cache = CellHeightsCache()
        let id = UUID()
        cache.storeCellHeight(40, forId: id, withCellIdentifier: "password", cellWidth: 300, isRichText: false, displaySignature: "alice")
        cache.storeCellHeight(80, forId: id, withCellIdentifier: "password", cellWidth: 300, isRichText: false, displaySignature: "bob")

        XCTAssertEqual(
            cache.cellHeight(forId: id, withCellIdentifier: "password", cellWidth: 300, isRichText: false, displaySignature: "alice"),
            40
        )
        XCTAssertEqual(
            cache.cellHeight(forId: id, withCellIdentifier: "password", cellWidth: 300, isRichText: false, displaySignature: "bob"),
            80
        )
    }
}

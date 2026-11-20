//
// PanelHeaderPresenterTests — filter bar hidden on Passwords tab (U08).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelHeaderPresenterTests: XCTestCase {
    func testFilterBarHiddenOnPasswords() {
        let history = PanelHeaderPresenter.model(tab: .history)
        XCTAssertTrue(history.showsFilterBar)
        let passwords = PanelHeaderPresenter.model(tab: .passwords)
        XCTAssertFalse(passwords.showsFilterBar)
    }

    func testSearchDebounceIs60ms() {
        XCTAssertEqual(PanelHeaderPresenter.searchDebounceMs, 60)
    }
}

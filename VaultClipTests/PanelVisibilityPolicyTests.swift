//
// PanelVisibilityPolicyTests — close / focus-restore rules for the history panel.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelVisibilityPolicyTests: XCTestCase {

    func testShouldCloseOnDeactivationWhenShownAndNotSuspended() {
        XCTAssertTrue(PanelVisibilityPolicy.shouldClose(
            reason: .appDeactivated, isShown: true, isSuspended: false
        ))
    }

    func testShouldNotCloseOnDeactivationWhenSuspended() {
        XCTAssertFalse(PanelVisibilityPolicy.shouldClose(
            reason: .appDeactivated, isShown: true, isSuspended: true
        ))
    }

    func testShouldNotCloseWhenAlreadyHidden() {
        XCTAssertFalse(PanelVisibilityPolicy.shouldClose(
            reason: .appDeactivated, isShown: false, isSuspended: false
        ))
    }

    func testShouldRestoreFocusForUserActionAndPasteOnly() {
        XCTAssertTrue(PanelVisibilityPolicy.shouldRestoreFocus(reason: .userAction))
        XCTAssertTrue(PanelVisibilityPolicy.shouldRestoreFocus(reason: .paste))
        XCTAssertFalse(PanelVisibilityPolicy.shouldRestoreFocus(reason: .appDeactivated))
    }
}

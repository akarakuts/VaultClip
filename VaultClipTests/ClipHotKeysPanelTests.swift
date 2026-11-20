//
// ClipHotKeysPanelTests — panel-scoped hot keys stay paused until activated.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ClipHotKeysPanelTests: XCTestCase {

    func testPanelScopedIncludesCmdBackslash() {
        XCTAssertTrue(ClipHotKeys.panelScoped.contains(where: { $0 === ClipHotKeys.cmdBackslash }))
    }

    func testSetPanelHotKeysActiveTogglesPause() {
        ClipHotKeys.setPanelHotKeysActive(false)
        for hotKey in ClipHotKeys.panelScoped {
            XCTAssertTrue(hotKey.isPaused)
        }
        XCTAssertFalse(ClipHotKeys.toggle.isPaused)

        ClipHotKeys.setPanelHotKeysActive(true)
        for hotKey in ClipHotKeys.panelScoped {
            XCTAssertFalse(hotKey.isPaused)
        }
        XCTAssertFalse(ClipHotKeys.toggle.isPaused)

        ClipHotKeys.setPanelHotKeysActive(false)
    }
}

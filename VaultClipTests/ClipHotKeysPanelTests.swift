//
// ClipHotKeysPanelTests — panel input uses local monitor; no Carbon panel keys (U04 / T05).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ClipHotKeysPanelTests: XCTestCase {

    func testPanelScopedCarbonRegistrationsAreEmpty() {
        XCTAssertTrue(ClipHotKeys.panelScoped.isEmpty)
        XCTAssertFalse(ClipHotKeys.toggle.isPaused)
    }

    func testLocalMonitorActiveOnlyWhenStarted() {
        let monitor = PanelLocalKeyMonitor()
        XCTAssertFalse(monitor.isActive)
        monitor.start()
        XCTAssertTrue(monitor.isActive)
        monitor.stop()
        XCTAssertFalse(monitor.isActive)
    }
}

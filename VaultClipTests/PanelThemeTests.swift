//
// PanelThemeTests — row height, hit targets, and Reduce Motion durations (U02).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelThemeTests: XCTestCase {

    func testRowHeightGrowsWithTextSizeAndSIsAtLeast36() {
        let s = PanelTheme.rowHeight(for: .s)
        let m = PanelTheme.rowHeight(for: .m)
        let l = PanelTheme.rowHeight(for: .l)
        let xl = PanelTheme.rowHeight(for: .xl)
        XCTAssertGreaterThanOrEqual(s, 36)
        XCTAssertGreaterThanOrEqual(m, s)
        XCTAssertGreaterThanOrEqual(l, m)
        XCTAssertGreaterThanOrEqual(xl, l)
    }

    func testHitTargetsAreAtLeast24() {
        XCTAssertGreaterThanOrEqual(PanelTheme.HitTarget.minimum, 24)
    }

    func testMotionDurationsRespectReduceMotion() {
        let normal = PanelTheme.motionDurations(reduceMotion: false)
        XCTAssertGreaterThan(normal.show, 0)
        XCTAssertGreaterThan(normal.hide, 0)
        XCTAssertGreaterThan(normal.hover, 0)
        XCTAssertGreaterThan(normal.toast, 0)

        let reduced = PanelTheme.motionDurations(reduceMotion: true)
        XCTAssertEqual(reduced.hover, 0)
        XCTAssertLessThanOrEqual(reduced.show, 0.1)
        XCTAssertLessThanOrEqual(reduced.hide, 0.1)
        XCTAssertEqual(reduced.fadeOnly, 0.1)
    }

    func testSettingsDecodeDefaultsPanelTextSizeToM() throws {
        let json = Data(#"{"panelPosition":2}"#.utf8)
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.panelTextSize, .m)
    }
}

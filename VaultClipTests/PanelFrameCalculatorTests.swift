//
// PanelFrameCalculatorTests — clamps, migration, and size persistence (U07).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelFrameCalculatorTests: XCTestCase {

    private let visible = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    func testEdgeWidthClamped() {
        XCTAssertEqual(PanelFrameCalculator.clampedEdgeWidth(100, visibleWidth: 1440), 360)
        XCTAssertEqual(PanelFrameCalculator.clampedEdgeWidth(2000, visibleWidth: 1440), 864) // 60%
        XCTAssertEqual(PanelFrameCalculator.clampedEdgeWidth(480, visibleWidth: 1440), 480)
    }

    func testCenterMinimumOnLargeDisplay() {
        let size = PanelFrameCalculator.clampedCenterSize(.zero, visible: visible.size)
        XCTAssertGreaterThanOrEqual(size.width, 640)
        XCTAssertGreaterThanOrEqual(size.height, 420)
    }

    func testLegacyMigrationFractions() {
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 8).0, .center)
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 8).1, 1.0 / 3.0)
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 4).1, 0.5)
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 5).1, 0.7)
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 6).1, 0.85)
        XCTAssertEqual(PanelFrameCalculator.migrateLegacyPosition(rawValue: 0).0, .right)
        XCTAssertNil(PanelFrameCalculator.migrateLegacyPosition(rawValue: 0).1)
    }

    func testSettingsDecodeMigratesLegacyCenter() throws {
        let json = Data(#"{"panelPosition":5}"#.utf8)
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.panelPosition, .center)
        XCTAssertEqual(settings.panelCenterWidth, -0.7, accuracy: 0.0001)
        XCTAssertEqual(settings.panelCenterHeight, -0.7, accuracy: 0.0001)
    }

    func testRightFrameUsesEdgeWidth() {
        let sizes = PanelSizeState(edgeWidth: 500, edgeHeight: 360, centerWidth: 0, centerHeight: 0)
        let frame = PanelFrameCalculator.frame(position: .right, visible: visible, screenFrame: screen, sizes: sizes)
        XCTAssertEqual(frame.width, 500)
        XCTAssertEqual(frame.maxX, screen.maxX)
    }

    func testMenuPositionsAreSixCases() {
        XCTAssertEqual(PanelPosition.allCases.count, 6)
        XCTAssertTrue(PanelPosition.allCases.contains(.center))
        XCTAssertFalse(PanelPosition.allCases.contains(where: { $0.rawValue == 4 }))
    }
}

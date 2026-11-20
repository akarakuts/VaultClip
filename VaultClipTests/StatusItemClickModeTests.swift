//
// StatusItemClickModeTests — click routing (U27).
//
import XCTest
@testable import VaultClip

final class StatusItemClickModeTests: XCTestCase {
    func testLeftClickRouting() {
        XCTAssertTrue(StatusItemPresentation.leftClickOpensPanel(mode: .openPanel))
        XCTAssertFalse(StatusItemPresentation.leftClickOpensPanel(mode: .openMenu))
    }

    func testAccessibilityTitles() {
        XCTAssertEqual(StatusItemPresentation.accessibilityTitle(isPaused: false), "VaultClip")
        XCTAssertTrue(StatusItemPresentation.accessibilityTitle(isPaused: true).contains("приостановлен"))
    }
}

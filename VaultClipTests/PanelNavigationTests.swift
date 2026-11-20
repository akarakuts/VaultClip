//
// PanelNavigationTests — quick-paste numbering and paging (U20).
//
import XCTest
@testable import VaultClip

final class PanelNavigationTests: XCTestCase {
    func testQuickPasteMapping() {
        XCTAssertEqual(PanelNavigation.displayedIndex(forQuickPasteKey: 1, visibleItemCount: 10), 0)
        XCTAssertEqual(PanelNavigation.displayedIndex(forQuickPasteKey: 9, visibleItemCount: 10), 8)
        XCTAssertEqual(PanelNavigation.displayedIndex(forQuickPasteKey: 0, visibleItemCount: 10), 9)
        XCTAssertNil(PanelNavigation.displayedIndex(forQuickPasteKey: 0, visibleItemCount: 5))
    }

    func testShortcutDigitsSkipHeaders() {
        XCTAssertEqual(PanelNavigation.shortcutDigit(forItemOrdinal: 1), 1)
        XCTAssertEqual(PanelNavigation.shortcutDigit(forItemOrdinal: 10), 0)
        XCTAssertNil(PanelNavigation.shortcutDigit(forItemOrdinal: 11))
    }

    func testOpenPolicyDefaults() {
        let policy = PanelOpenPolicy()
        XCTAssertEqual(policy.initialTab(lastTab: .favorites), .history)
        XCTAssertEqual(policy.initialSelectedIndex(itemCount: 3), 0)
        var second = PanelOpenPolicy()
        second.selectSecondItem = true
        XCTAssertEqual(second.initialSelectedIndex(itemCount: 3), 1)
    }

    func testPageAndScroll() {
        XCTAssertEqual(PanelNavigation.pageSize(visibleRowHeight: 40, viewportHeight: 400), 10)
        XCTAssertEqual(PanelNavigation.indexAfterPage(current: 0, direction: 1, pageSize: 10, count: 25), 10)
        XCTAssertEqual(PanelNavigation.scrollTargetRow(selected: 0, firstVisible: 0, lastVisible: 9, count: 20), 0)
        XCTAssertEqual(PanelNavigation.scrollTargetRow(selected: 9, firstVisible: 0, lastVisible: 9, count: 20), 10)
    }
}

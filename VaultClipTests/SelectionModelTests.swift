//
// SelectionModelTests — ordered multi-select (U16).
//
import XCTest
@testable import VaultClip

final class SelectionModelTests: XCTestCase {
    func testToggleAndRange() {
        let a = UUID(), b = UUID(), c = UUID()
        let order = [a, b, c]
        var model = SelectionModel()
        model.selectSingle(a)
        model.toggle(c, visibleOrder: order)
        XCTAssertEqual(model.orderedIds, [a, c])
        // Anchor is c; ⇧ to b selects b…c.
        model.selectRange(to: b, visibleOrder: order)
        XCTAssertEqual(model.orderedIds, [b, c])
    }

    func testRetainVisible() {
        let a = UUID(), b = UUID(), c = UUID()
        var model = SelectionModel()
        model.selectAll(visibleOrder: [a, b, c])
        model.retainVisible([a, c], visibleOrder: [a, c])
        XCTAssertEqual(model.orderedIds, [a, c])
    }
}

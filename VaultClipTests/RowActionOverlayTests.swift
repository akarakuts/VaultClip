//
// RowActionOverlayTests — button sets by kind/tab (U15).
//
import XCTest
@testable import VaultClip

final class RowActionOverlayTests: XCTestCase {
    func testOrdinaryTextRow() {
        let buttons = RowActionOverlay.buttons(kind: .text, isFavorite: false, tab: .history)
        XCTAssertEqual(buttons.map(\.id), [.paste, .toggleFavorite, .more])
    }

    func testRichTextIncludesPlainPaste() {
        let buttons = RowActionOverlay.buttons(kind: .richText, isFavorite: true, tab: .history)
        XCTAssertEqual(buttons.map(\.id), [.paste, .pastePlainText, .toggleFavorite, .more])
        XCTAssertEqual(buttons.first(where: { $0.id == .toggleFavorite })?.symbolName, "star.fill")
    }

    func testPasswordRow() {
        let buttons = RowActionOverlay.buttons(kind: .password, isFavorite: false, tab: .passwords)
        XCTAssertEqual(buttons.map(\.id), [.copyLogin, .copyPassword, .more])
    }
}

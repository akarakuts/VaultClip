//
// EditBeforePasteTests — availability and Esc stack (U24).
//
import XCTest
@testable import VaultClip

final class EditBeforePasteTests: XCTestCase {
    func testAvailability() {
        XCTAssertEqual(EditBeforePaste.availability(for: .text), .available)
        XCTAssertEqual(EditBeforePaste.availability(for: .richText), .availableWithRichTextWarning)
        XCTAssertEqual(EditBeforePaste.availability(for: .password), .unavailable)
        XCTAssertEqual(EditBeforePaste.availability(for: .image), .unavailable)
        XCTAssertEqual(EditBeforePaste.availability(for: .file(2)), .unavailable)
    }

    func testEscapeStack() {
        XCTAssertEqual(EditBeforePaste.escapeAction(isEditing: true, isDirty: true, canClosePanel: true), .confirmDiscard)
        XCTAssertEqual(EditBeforePaste.escapeAction(isEditing: true, isDirty: false, canClosePanel: true), .leaveEditor)
        XCTAssertEqual(EditBeforePaste.escapeAction(isEditing: false, isDirty: false, canClosePanel: true), .closePanel)
    }
}

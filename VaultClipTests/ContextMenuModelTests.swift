//
// ContextMenuModelTests — registry-backed menu sections (U17).
//
import XCTest
@testable import VaultClip

final class ContextMenuModelTests: XCTestCase {
    func testTextMenuHasPasteAndDelete() {
        let model = ContextMenuBuilder.build(
            kind: .text,
            isPassword: false,
            isFavorite: false,
            selectionCount: 1,
            sourceAppName: "Safari"
        )
        let sectionIDs = model.sections.map(\.section)
        XCTAssertTrue(sectionIDs.contains(.paste))
        XCTAssertTrue(sectionIDs.contains(.filter))
        XCTAssertTrue(sectionIDs.contains(.delete))
        XCTAssertTrue(sectionIDs.contains(.password))
    }

    func testPasswordMenuOmitsSaveToPasswords() {
        let model = ContextMenuBuilder.build(
            kind: .password,
            isPassword: true,
            isFavorite: false,
            selectionCount: 1,
            sourceAppName: nil
        )
        let passwordTitles = model.sections.first(where: { $0.section == .password })?.items.map(\.titleKey) ?? []
        XCTAssertTrue(passwordTitles.contains("copyLogin"))
        XCTAssertFalse(passwordTitles.contains("saveToPasswords"))
    }
}

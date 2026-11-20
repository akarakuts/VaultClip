//
// DragOutPayloadTests — external drag types (U19).
//
import XCTest
@testable import VaultClip

final class DragOutPayloadTests: XCTestCase {
    func testPasswordExcluded() {
        XCTAssertTrue(DragOutPayload.externalTypes(for: .password, isPassword: true).isEmpty)
        XCTAssertTrue(DragOutPayload.externalTypes(for: .text, isPassword: true).isEmpty)
    }

    func testLinkAndImageTypes() {
        XCTAssertEqual(DragOutPayload.externalTypes(for: .link, isPassword: false), [.url, .plainText])
        XCTAssertEqual(DragOutPayload.externalTypes(for: .image, isPassword: false), [.image, .fileURL])
    }

    func testInternalReorderRules() {
        XCTAssertTrue(DragOutPayload.allowsInternalReorder(selectionCount: 1, tab: .history, isSearching: false))
        XCTAssertFalse(DragOutPayload.allowsInternalReorder(selectionCount: 2, tab: .history, isSearching: false))
        XCTAssertFalse(DragOutPayload.allowsInternalReorder(selectionCount: 1, tab: .passwords, isSearching: false))
    }
}

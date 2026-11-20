//
// MultiPasteComposerTests — join rules and password exclusion (U16).
//
import XCTest
@testable import VaultClip

final class MultiPasteComposerTests: XCTestCase {
    func testJoinsTextWithNewline() {
        let result = MultiPasteComposer.compose(items: [
            .init(kind: .text, text: "a", isPassword: false),
            .init(kind: .text, text: "b", isPassword: false)
        ])
        XCTAssertEqual(result.payload, .joinedText("a\nb"))
    }

    func testExcludesPasswords() {
        let result = MultiPasteComposer.compose(items: [
            .init(kind: .password, text: "secret", isPassword: true),
            .init(kind: .text, text: "ok", isPassword: false)
        ])
        XCTAssertEqual(result.payload, .joinedText("ok"))
        XCTAssertEqual(result.skippedPasswords, 1)
    }

    func testMixedSkipsImages() {
        let result = MultiPasteComposer.compose(items: [
            .init(kind: .text, text: "a", isPassword: false),
            .init(kind: .image, text: nil, isPassword: false)
        ])
        XCTAssertEqual(result.payload, .joinedText("a"))
        XCTAssertEqual(result.skippedImages, 1)
    }
}

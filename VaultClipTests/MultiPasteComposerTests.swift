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

    func testSeparatorsAndReverseAndDiscrete() {
        let items = [
            MultiPasteComposer.Item(kind: .text, text: "a", isPassword: false),
            MultiPasteComposer.Item(kind: .text, text: "b", isPassword: false)
        ]
        XCTAssertEqual(
            MultiPasteComposer.compose(items: items, separator: .comma).payload,
            .joinedText("a, b")
        )
        XCTAssertEqual(
            MultiPasteComposer.compose(items: items, separator: .tab, reverse: true).payload,
            .joinedText("b\ta")
        )
        XCTAssertEqual(
            MultiPasteComposer.compose(items: items, separator: .space).payload,
            .joinedText("a b")
        )
        XCTAssertEqual(
            MultiPasteComposer.compose(items: items, separator: .blankLine).payload,
            .joinedText("a\n\nb")
        )
        let images = [
            MultiPasteComposer.Item(kind: .image, text: nil, isPassword: false),
            MultiPasteComposer.Item(kind: .image, text: nil, isPassword: false)
        ]
        XCTAssertEqual(MultiPasteComposer.compose(items: images).payload, .discreteItems(count: 2))
        let files = [MultiPasteComposer.Item(kind: .file(1), text: nil, isPassword: false)]
        XCTAssertEqual(MultiPasteComposer.compose(items: files).payload, .discreteItems(count: 1))
        let empty = MultiPasteComposer.compose(items: [
            MultiPasteComposer.Item(kind: .text, text: nil, isPassword: false)
        ])
        XCTAssertNil(empty.payload)
    }

}

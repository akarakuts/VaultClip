//
// KeyChordMatcherCoverageTests — ANSI tables and non-letter keys (U03).
//
import XCTest
@testable import VaultClip

private struct FixedTranslator: KeyboardLayoutTranslating {
    var map: [UInt16: Character] = [:]
    func character(forKeyCode keyCode: UInt16) -> Character? { map[keyCode] }
}

final class KeyChordMatcherCoverageTests: XCTestCase {
    func testNonLetterKeys() {
        let codes: [(UInt16, LogicalKey)] = [
            (36, .return), (49, .space), (53, .escape), (48, .tab), (51, .delete),
            (117, .forwardDelete), (126, .upArrow), (125, .downArrow), (123, .leftArrow),
            (124, .rightArrow), (116, .pageUp), (121, .pageDown), (115, .home), (119, .end),
            (24, .equal), (27, .minus), (44, .slash), (33, .leftBracket), (30, .rightBracket),
            (43, .comma)
        ]
        for (code, key) in codes {
            XCTAssertEqual(KeyChordMatcher.nonLetterKey(forKeyCode: code), key)
        }
        XCTAssertNil(KeyChordMatcher.nonLetterKey(forKeyCode: 999))
    }

    func testAnsiFallbackAndTranslator() {
        XCTAssertEqual(KeyChordMatcher.ansiLogicalKey(forKeyCode: 0), .letter("a"))
        XCTAssertEqual(KeyChordMatcher.ansiLogicalKey(forKeyCode: 18), .digit(1))
        XCTAssertNil(KeyChordMatcher.ansiLogicalKey(forKeyCode: 200))
        var translator = FixedTranslator(map: [12: "Q", 18: "1"])
        let matcher = KeyChordMatcher(translator: translator)
        XCTAssertEqual(matcher.chord(keyCode: 12, modifiers: .command)?.key, .letter("q"))
        XCTAssertEqual(matcher.chord(keyCode: 18, modifiers: [])?.key, .digit(1))
        translator.map = [:]
        let fallback = KeyChordMatcher(translator: translator)
        XCTAssertEqual(fallback.chord(keyCode: 14, modifiers: [])?.key, .letter("e"))
        XCTAssertTrue(fallback.matches(KeyChord(key: .return, modifiers: []), keyCode: 36, modifiers: []))
        XCTAssertFalse(fallback.matches(KeyChord.cmd("k"), keyCode: 36, modifiers: []))
    }
}

//
// KeyChordMatcher — map NSEvent / keyCode+mods to KeyChord via layout translator (U03).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Carbon
import CoreGraphics

protocol KeyboardLayoutTranslating {
    /// Character produced by `keyCode` under the active ASCII-capable layout (lowercase letter or digit).
    func character(forKeyCode keyCode: UInt16) -> Character?
}

struct KeyChordMatcher {
    var translator: KeyboardLayoutTranslating

    init(translator: KeyboardLayoutTranslating = ASCIICapableLayoutTranslator()) {
        self.translator = translator
    }

    func chord(keyCode: UInt16, modifiers: KeyModifiers) -> KeyChord? {
        if let nonLetter = Self.nonLetterKey(forKeyCode: keyCode) {
            return KeyChord(key: nonLetter, modifiers: modifiers)
        }
        if let ch = translator.character(forKeyCode: keyCode) {
            if ch.isLetter {
                return KeyChord(key: .letter(Character(ch.lowercased())), modifiers: modifiers)
            }
            if let d = ch.wholeNumberValue, (0...9).contains(d) {
                return KeyChord(key: .digit(d), modifiers: modifiers)
            }
        }
        // ANSI QWERTY fallback for letters/digits when layout translate fails.
        if let ansi = Self.ansiLogicalKey(forKeyCode: keyCode) {
            return KeyChord(key: ansi, modifiers: modifiers)
        }
        return nil
    }

    func chord(from event: NSEvent) -> KeyChord? {
        chord(keyCode: UInt16(event.keyCode), modifiers: .from(flags: event.modifierFlags))
    }

    func matches(_ chord: KeyChord, keyCode: UInt16, modifiers: KeyModifiers) -> Bool {
        guard let resolved = self.chord(keyCode: keyCode, modifiers: modifiers) else { return false }
        return resolved == chord
    }

    // MARK: - ANSI / keyCode tables

    /// Hardware keyCodes that are layout-independent.
    static func nonLetterKey(forKeyCode keyCode: UInt16) -> LogicalKey? {
        switch keyCode {
        case 36: return .return
        case 49: return .space
        case 53: return .escape
        case 48: return .tab
        case 51: return .delete
        case 117: return .forwardDelete
        case 126: return .upArrow
        case 125: return .downArrow
        case 123: return .leftArrow
        case 124: return .rightArrow
        case 116: return .pageUp
        case 121: return .pageDown
        case 115: return .home
        case 119: return .end
        case 24: return .equal
        case 27: return .minus
        case 44: return .slash
        case 33: return .leftBracket
        case 30: return .rightBracket
        case 43: return .comma
        default: return nil
        }
    }

    /// US ANSI letter/digit map used when layout translation is unavailable.
    static func ansiLogicalKey(forKeyCode keyCode: UInt16) -> LogicalKey? {
        let letters: [UInt16: Character] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t",
            31: "o", 32: "u", 34: "i", 35: "p", 37: "l", 38: "j", 40: "k",
            45: "n", 46: "m"
        ]
        if let ch = letters[keyCode] { return .letter(ch) }
        let digits: [UInt16: Int] = [
            29: 0, 18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9
        ]
        if let d = digits[keyCode] { return .digit(d) }
        return nil
    }
}

/// Live translator via `TISCopyCurrentASCIICapableKeyboardLayoutInputSource` + `UCKeyTranslate`.
struct ASCIICapableLayoutTranslator: KeyboardLayoutTranslating {
    func character(forKeyCode keyCode: UInt16) -> Character? {
        guard let data = Self.layoutData() else { return nil }
        guard let produced = Self.translate(keyCode: keyCode, layoutData: data)?.lowercased(),
              let ch = produced.first else { return nil }
        return ch
    }

    private static func layoutData() -> Data? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        return unsafeBitCast(raw, to: CFData.self) as Data
    }

    private static func translate(keyCode: UInt16, layoutData: Data) -> String? {
        layoutData.withUnsafeBytes { rawBuffer -> String? in
            guard let base = rawBuffer.baseAddress else { return nil }
            let layout = base.assumingMemoryBound(to: UCKeyboardLayout.self)
            var deadKeyState: UInt32 = 0
            var chars: [UniChar] = Array(repeating: 0, count: 4)
            var length = 0
            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length)
        }
    }
}

/// Deterministic map for tests (US / Russian physical / Dvorak keyCode → Latin letter).
struct MapLayoutTranslator: KeyboardLayoutTranslating {
    var map: [UInt16: Character]

    func character(forKeyCode keyCode: UInt16) -> Character? {
        map[keyCode]
    }

    /// US QWERTY: keyCode → letter.
    static var us: MapLayoutTranslator {
        var map: [UInt16: Character] = [:]
        for code in UInt16(0)...UInt16(127) {
            if case let .letter(ch)? = KeyChordMatcher.ansiLogicalKey(forKeyCode: code) {
                map[code] = ch
            } else if case let .digit(d)? = KeyChordMatcher.ansiLogicalKey(forKeyCode: code) {
                map[code] = Character("\(d)")
            }
        }
        return MapLayoutTranslator(map: map)
    }

    /// Russian ЙЦУКЕН physical keys produce Cyrillic; ASCII-capable source still yields Latin for shortcuts.
    /// For tests we treat the physical «л» key (US `k`, code 40) as producing `k` via ASCII-capable layout.
    static var russianPhysical: MapLayoutTranslator { us }

    /// Dvorak: `k` lives on ANSI keyCode 40 still maps via custom table — use letter positions from Dvorak.
    /// Physical key that types `k` on Dvorak is ANSI `v` (keyCode 9).
    static var dvorak: MapLayoutTranslator {
        // Minimal map covering letters used by panel chords.
        MapLayoutTranslator(map: [
            9: "k",   // physical V → k on Dvorak
            3: "f",   // keep f for ⌘F tests if needed
            1: "s",
            2: "d",
            14: "e",
            16: "y",
            13: "w",
            0: "a",
            6: "z",
            31: "o",
            15: "r",
            40: "t",  // physical K → t on Dvorak (not k)
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
            22: "6", 26: "7", 28: "8", 25: "9", 29: "0"
        ])
    }
}

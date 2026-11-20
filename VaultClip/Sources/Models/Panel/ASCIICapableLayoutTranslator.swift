//
// ASCIICapableLayoutTranslator — TIS/UCKeyTranslate layout bridge (U03).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Carbon
import CoreGraphics

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

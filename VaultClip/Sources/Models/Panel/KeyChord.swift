//
// KeyChord — layout-independent logical key + modifiers for panel commands (U03).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

struct KeyModifiers: OptionSet, Hashable {
    let rawValue: Int
    static let command = KeyModifiers(rawValue: 1 << 0)
    static let shift = KeyModifiers(rawValue: 1 << 1)
    static let option = KeyModifiers(rawValue: 1 << 2)
    static let control = KeyModifiers(rawValue: 1 << 3)
}

enum LogicalKey: Hashable {
    case letter(Character) // a–z
    case digit(Int) // 0–9
    case `return`
    case space
    case escape
    case tab
    case delete // ⌫
    case forwardDelete
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case pageUp
    case pageDown
    case home
    case end
    case equal
    case minus
    case slash
    case leftBracket
    case rightBracket
    case comma
}

struct KeyChord: Hashable {
    var key: LogicalKey
    var modifiers: KeyModifiers

    static func cmd(_ letter: Character) -> KeyChord {
        KeyChord(key: .letter(Character(letter.lowercased())), modifiers: .command)
    }

    static func cmdDigit(_ n: Int) -> KeyChord {
        KeyChord(key: .digit(n), modifiers: .command)
    }

    static func optionCmdDigit(_ n: Int) -> KeyChord {
        KeyChord(key: .digit(n), modifiers: [.option, .command])
    }
}

extension KeyModifiers {
    static func from(flags: NSEvent.ModifierFlags) -> KeyModifiers {
        var mods = KeyModifiers()
        if flags.contains(.command) { mods.insert(.command) }
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.option) { mods.insert(.option) }
        if flags.contains(.control) { mods.insert(.control) }
        return mods
    }
}

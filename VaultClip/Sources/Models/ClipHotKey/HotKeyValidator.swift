//
// HotKeyValidator — rejects system/panel conflicts for the global toggle (T27).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import HotKey

enum HotKeyValidationError: Error, Equatable {
    case needsModifier
    case systemShortcut
    case panelConflict
    case invalidKey

    var localizedMessage: String {
        switch self {
        case .needsModifier: return L10n.hotkeyErrorNeedsModifier
        case .systemShortcut: return L10n.hotkeyErrorSystemShortcut
        case .panelConflict: return L10n.hotkeyErrorPanelConflict
        case .invalidKey: return L10n.hotkeyErrorInvalidKey
        }
    }
}

enum HotKeyValidator {
    static func validate(key: Key, modifiers: NSEvent.ModifierFlags) -> Result<KeyCombo, HotKeyValidationError> {
        let mods = filterModifiers(modifiers)
        guard filterKeys([key]).count == 1 else {
            return .failure(.invalidKey)
        }
        let hasPrimary = mods.contains(.command) || mods.contains(.control) || mods.contains(.option)
        if !hasPrimary && !isFunctionKey(key: key) {
            return .failure(.needsModifier)
        }
        if isSystemForbidden(key: key, modifiers: mods) {
            return .failure(.systemShortcut)
        }
        if conflictsWithPanelScoped(key: key, modifiers: mods) {
            return .failure(.panelConflict)
        }
        return .success(KeyCombo(key: key, modifiers: mods))
    }

    private static func conflictsWithPanelScoped(key: Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard let logical = logicalKey(from: key) else { return false }
        let chord = KeyChord(key: logical, modifiers: .from(flags: modifiers))
        return FocusZone.allCases.contains { zone in
            !PanelCommandRegistry.commands(matching: chord, in: zone).isEmpty
        }
    }

    private static func logicalKey(from key: Key) -> LogicalKey? {
        switch key {
        case .a: return .letter("a")
        case .b: return .letter("b")
        case .c: return .letter("c")
        case .d: return .letter("d")
        case .e: return .letter("e")
        case .f: return .letter("f")
        case .g: return .letter("g")
        case .h: return .letter("h")
        case .i: return .letter("i")
        case .j: return .letter("j")
        case .k: return .letter("k")
        case .l: return .letter("l")
        case .m: return .letter("m")
        case .n: return .letter("n")
        case .o: return .letter("o")
        case .p: return .letter("p")
        case .q: return .letter("q")
        case .r: return .letter("r")
        case .s: return .letter("s")
        case .t: return .letter("t")
        case .u: return .letter("u")
        case .v: return .letter("v")
        case .w: return .letter("w")
        case .x: return .letter("x")
        case .y: return .letter("y")
        case .z: return .letter("z")
        case .zero: return .digit(0)
        case .one: return .digit(1)
        case .two: return .digit(2)
        case .three: return .digit(3)
        case .four: return .digit(4)
        case .five: return .digit(5)
        case .six: return .digit(6)
        case .seven: return .digit(7)
        case .eight: return .digit(8)
        case .nine: return .digit(9)
        case .return: return .return
        case .space: return .space
        case .escape: return .escape
        case .tab: return .tab
        case .delete: return .delete
        case .upArrow: return .upArrow
        case .downArrow: return .downArrow
        case .leftArrow: return .leftArrow
        case .rightArrow: return .rightArrow
        case .pageUp: return .pageUp
        case .pageDown: return .pageDown
        case .home: return .home
        case .end: return .end
        case .equal: return .equal
        case .minus: return .minus
        case .slash: return .slash
        case .leftBracket: return .leftBracket
        case .rightBracket: return .rightBracket
        case .comma: return .comma
        default: return nil
        }
    }

    private static func isSystemForbidden(key: Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        let cmd = modifiers.contains(.command)
        let ctrl = modifiers.contains(.control)
        let shift = modifiers.contains(.shift)
        let opt = modifiers.contains(.option)

        if cmd && !ctrl && !opt {
            if shift {
                if key == .z { return true } // ⌘⇧Z
                if [.three, .four, .five].contains(key) { return true } // screenshots
            } else {
                switch key {
                case .c, .v, .x, .z, .a, .q, .w, .h, .m, .s, .n, .t, .o, .p, .f, .space, .comma, .period:
                    return true
                default:
                    break
                }
            }
        }
        if ctrl && !cmd && !opt && !shift, key == .space {
            return true
        }
        return false
    }
}

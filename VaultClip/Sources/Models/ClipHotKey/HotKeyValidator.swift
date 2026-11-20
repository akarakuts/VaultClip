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
        ClipHotKeys.panelScoped.contains { hotKey in
            hotKey.keyCombo.key == key && hotKey.keyCombo.modifiers == modifiers
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

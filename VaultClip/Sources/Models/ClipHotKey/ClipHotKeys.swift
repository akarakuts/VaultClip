//
//  ClipHotKeys.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct ClipHotKeys {
    
    /// Global toggle — registered at launch.
    static var toggle = ClipHotKey(key: .v, modifiers: [.command, .shift], startsPaused: false)

    static var `return` = ClipHotKey(key: .return, modifiers: [])
    static var shiftReturn = ClipHotKey(key: .return, modifiers: [.shift])
    static var escape = ClipHotKey(key: .escape, modifiers: [])
    static var downArrow = ClipHotKey(key: .downArrow, modifiers: [])
    static var upArrow = ClipHotKey(key: .upArrow, modifiers: [])
    static var pageDown = ClipHotKey(key: .pageDown, modifiers: [])
    static var pageUp = ClipHotKey(key: .pageUp, modifiers: [])
    static var ctrlAltCmdLeftArrow = ClipHotKey(key: .leftArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdRightArrow = ClipHotKey(key: .rightArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdDownArrow = ClipHotKey(key: .downArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdUpArrow = ClipHotKey(key: .upArrow, modifiers: [.control, .option, .command])
    static var ctrlDelete = ClipHotKey(key: .delete, modifiers: [.control])
    static var ctrlSpace = ClipHotKey(key: .space, modifiers: [.control])
    static var cmdBackslash = ClipHotKey(key: .backslash, modifiers: [.command])
    static var ctrlLeftBracket = ClipHotKey(key: .leftBracket, modifiers: [.control])
    static var ctrlRightBracket = ClipHotKey(key: .rightBracket, modifiers: [.control])
    
    static var cmd0 = ClipHotKey(key: .zero, modifiers: [.command])
    static var cmd1 = ClipHotKey(key: .one, modifiers: [.command])
    static var cmd2 = ClipHotKey(key: .two, modifiers: [.command])
    static var cmd3 = ClipHotKey(key: .three, modifiers: [.command])
    static var cmd4 = ClipHotKey(key: .four, modifiers: [.command])
    static var cmd5 = ClipHotKey(key: .five, modifiers: [.command])
    static var cmd6 = ClipHotKey(key: .six, modifiers: [.command])
    static var cmd7 = ClipHotKey(key: .seven, modifiers: [.command])
    static var cmd8 = ClipHotKey(key: .eight, modifiers: [.command])
    static var cmd9 = ClipHotKey(key: .nine, modifiers: [.command])

    /// Hot keys that must only be registered while the history panel is visible.
    static var panelScoped: [ClipHotKey] {
        [
            `return`, shiftReturn, escape, downArrow, upArrow, pageDown, pageUp,
            ctrlAltCmdLeftArrow, ctrlAltCmdRightArrow, ctrlAltCmdDownArrow, ctrlAltCmdUpArrow,
            ctrlDelete, ctrlSpace, cmdBackslash, ctrlLeftBracket, ctrlRightBracket,
            cmd0, cmd1, cmd2, cmd3, cmd4, cmd5, cmd6, cmd7, cmd8, cmd9
        ]
    }

    static func setPanelHotKeysActive(_ active: Bool) {
        for hotKey in panelScoped {
            hotKey.isPaused = !active
        }
    }
}

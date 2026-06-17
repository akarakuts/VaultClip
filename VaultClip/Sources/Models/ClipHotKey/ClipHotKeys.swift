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
    
    static var toggle = ClipHotKey(key: .v, modifiers: [.command, .shift])
    static var `return` = ClipHotKey(key: .return, modifiers: [])
    static var escape = ClipHotKey(key: .escape, modifiers: [])
    static var downArrow = ClipHotKey(key: .downArrow, modifiers: [])
    static var upArrow = ClipHotKey(key: .upArrow, modifiers: [])
    static var leftArrow = ClipHotKey(key: .leftArrow, modifiers: [])
    static var rightArrow = ClipHotKey(key: .rightArrow, modifiers: [])
    static var pageDown = ClipHotKey(key: .pageDown, modifiers: [])
    static var pageUp = ClipHotKey(key: .pageUp, modifiers: [])
    static var ctrlAltCmdLeftArrow = ClipHotKey(key: .leftArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdRightArrow = ClipHotKey(key: .rightArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdDownArrow = ClipHotKey(key: .downArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdUpArrow = ClipHotKey(key: .upArrow, modifiers: [.control, .option, .command])
    static var ctrlDelete = ClipHotKey(key: .delete, modifiers: [.control])
    static var ctrlSpace = ClipHotKey(key: .space, modifiers: [.control])
    static var cmdBackslash = ClipHotKey(key: .backslash, modifiers: [.command])
    static var cmdShiftF = ClipHotKey(key: .f, modifiers: [.command, .shift])
    static var cmdShiftP = ClipHotKey(key: .p, modifiers: [.command, .shift])
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
}

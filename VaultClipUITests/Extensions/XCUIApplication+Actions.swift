//
//  XCUIApplication+Actions.swift
//  VaultClipUITests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest

extension XCUIApplication {
    
    func quit() {
        statusItemButton.click()
        quitButton.click()
    }
    
    func pressHotKey() {
        typeKey("v", modifierFlags: .init(arrayLiteral: .command, .shift))
    }
    
    func typeKey(_ key: XCUIKeyboardKey) {
        typeKey(key, modifierFlags: .init())
    }
}

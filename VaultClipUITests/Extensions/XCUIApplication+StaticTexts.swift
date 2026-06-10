//
//  XCUIApplication+StaticTexts.swift
//  VaultClipUITests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest

extension XCUIApplication {
    
    var waitingForControlLabel: XCUIElement {
        return helpWindow.staticTexts[Accessibility.identifiers.waitingForControlLabel]
    }
    
    var howToUseLabel: XCUIElement {
        return helpWindow.staticTexts[Accessibility.identifiers.howToUseLabel]
    }
}

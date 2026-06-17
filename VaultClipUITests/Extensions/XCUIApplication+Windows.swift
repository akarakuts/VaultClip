//
//  XCUIApplication+Windows.swift
//  VaultClipUITests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest

extension XCUIApplication {
    
    var welcomeWindow: XCUIElement {
        return windows[Accessibility.identifiers.welcomeWindow]
    }
    
    var helpWindow: XCUIElement {
        return windows[Accessibility.identifiers.helpWindow]
    }
    
    var aboutWindow: XCUIElement {
        return windows[Accessibility.identifiers.aboutWindow]
    }
    
    var historyWindow: XCUIElement {
        return windows[Accessibility.identifiers.historyWindow]
    }
}

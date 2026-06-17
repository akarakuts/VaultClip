//
//  XCUIApplication+Buttons.swift
//  VaultClipUITests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest

extension XCUIApplication {
    
    var welcomeAllowAccessButton: XCUIElement {
        return welcomeWindow.buttons[Accessibility.identifiers.welcomeAllowAccessButton]
    }
    
    var statusItemButton: XCUIElement {
        return self.statusItems[Accessibility.identifiers.statusItemButton]
    }
    
    var toggleHistoryWindowButton: XCUIElement {
        return self.menus.menuItems[Accessibility.identifiers.toggleHistoryWindowButton]
    }
    
    var quitButton: XCUIElement {
        return self.menus.menuItems[Accessibility.identifiers.quitButton]
    }
    
    var helpButton: XCUIElement {
        return self.menus.menuItems[Accessibility.identifiers.helpButton]
    }
    
    var aboutButton: XCUIElement {
        return self.menus.menuItems[Accessibility.identifiers.aboutButton]
    }
    
    var positionButton: XCUIElement {
        return self.menus.menuItems[Accessibility.identifiers.positionButton]
    }
    
    var positionLeftButton: XCUIElement {
        return positionButton.menus.menuItems[Accessibility.identifiers.positionLeftButton]
    }
    
    var positionRightButton: XCUIElement {
        return positionButton.menus.menuItems[Accessibility.identifiers.positionRightButton]
    }
    
    var positionTopButton: XCUIElement {
        return positionButton.menus.menuItems[Accessibility.identifiers.positionTopButton]
    }
    
    var positionBottomButton: XCUIElement {
        return positionButton.menus.menuItems[Accessibility.identifiers.positionBottomButton]
    }
}

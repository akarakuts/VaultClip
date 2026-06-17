//
//  HelpWindowController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HelpWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.title = L10n.helpWindowTitle
        window?.setAccessibilityIdentifier(Accessibility.identifiers.helpWindow)
    }
    
    static func createHelpWindowController() -> HelpWindowController {
        return NSStoryboard.instantiateOrTerminate(identifier: "HelpWindowController")
    }
}

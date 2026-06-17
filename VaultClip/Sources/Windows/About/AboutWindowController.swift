//
//  AboutWindowController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class AboutWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.setAccessibilityIdentifier(Accessibility.identifiers.aboutWindow)
    }
    
    static func createAboutWindowController() -> AboutWindowController {
        return NSStoryboard.instantiateOrTerminate(identifier: "AboutWindowController")
    }
}

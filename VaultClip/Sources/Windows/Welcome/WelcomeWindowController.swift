//
//  WelcomeWindowController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class WelcomeWindowController: NSWindowController, NSWindowDelegate {
    
    var closeButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.delegate = self
        window?.setAccessibilityIdentifier(Accessibility.identifiers.welcomeWindow)
        closeButton = window?.standardWindowButton(.closeButton)
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
    }
    
    static func createWelcomeWindowController() -> WelcomeWindowController {
        return NSStoryboard.instantiateOrTerminate(identifier: "WelcomeWindowController")
    }
    
    @objc func closeButtonClicked() {
        NSApplication.shared.terminate(self)
    }
}

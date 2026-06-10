//
//  WelcomeViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class WelcomeViewController: NSViewController {
    
    @IBOutlet var allowAccessButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allowAccessButton.setAccessibilityIdentifier(Accessibility.identifiers.welcomeAllowAccessButton)
    }
    
    @IBAction func allowAccessTapped(_ sender: Any) {
        view.window?.close()
        Controller.main.helpWindowController.showWindow(sender)
        _ = Helper.isControlGranted(showPopup: true)
    }
}

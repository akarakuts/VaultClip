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
        
        allowAccessButton.title = L10n.welcomeAllowAccess
        allowAccessButton.setAccessibilityIdentifier(Accessibility.identifiers.welcomeAllowAccessButton)
        localizeLabels()
    }

    private func localizeLabels() {
        for subview in view.subviews {
            guard let field = subview as? NSTextField else { continue }
            switch field.stringValue {
            case "Thank you for downloading VaultClip!":
                field.stringValue = L10n.welcomeTitle
            case let text where text.contains("paste into your applications"):
                field.stringValue = L10n.welcomeBody
            default:
                break
            }
        }
    }
    
    @IBAction func allowAccessTapped(_ sender: Any) {
        view.window?.close()
        _ = AccessControlHelper.requestSystemPromptIfNeeded()
        Controller.main.helpWindowController.showWindow(sender)
    }
}

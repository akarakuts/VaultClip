//
//  WaitingViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class WaitingViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeUI()
    }

    private func localizeUI() {
        if let titleField = view.descendantView(withAccessibilityIdentifier: "waitingForControlLabel") as? NSTextField {
            titleField.stringValue = L10n.helpWaitingTitle
        }
        for subview in view.subviews {
            if let field = subview as? NSTextField, field.stringValue.contains("cannot be used until") {
                field.stringValue = L10n.helpWaitingBody
            }
            if let button = subview as? NSButton, button.title == "Allow Access" {
                button.title = L10n.welcomeAllowAccess
            }
        }
    }
    
    @IBAction func allowAccessClicked(_ sender: Any) {
        if Helper.isControlGranted(showPopup: false) { return }
        if !AccessControlHelper.hasShownSystemPrompt() {
            _ = AccessControlHelper.requestSystemPromptIfNeeded()
            return
        }
        Helper.openAccessibilitySettings()
    }
}

//
// WelcomeViewController — first-launch Accessibility ask; no auto-Help after grant.
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class WelcomeViewController: NSViewController {

    @IBOutlet var allowAccessButton: NSButton!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var bodyLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        allowAccessButton.title = L10n.welcomeAllowAccess
        allowAccessButton.setAccessibilityIdentifier(Accessibility.identifiers.welcomeAllowAccessButton)
        // Prefer outlets; fall back to font/size heuristics if storyboard outlets are missing.
        resolveLabelsIfNeeded()
        titleLabel?.stringValue = L10n.welcomeTitle
        bodyLabel?.stringValue = L10n.welcomeBody
        bodyLabel?.maximumNumberOfLines = 0
        bodyLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.setAccessibilityRole(.staticText)
        bodyLabel?.setAccessibilityRole(.staticText)
    }

    private func resolveLabelsIfNeeded() {
        if titleLabel != nil, bodyLabel != nil { return }
        let fields = view.subviews.compactMap { $0 as? NSTextField }
        // Title uses the larger system font in the storyboard (size 20).
        let sorted = fields.sorted {
            ($0.font?.pointSize ?? 0) > ($1.font?.pointSize ?? 0)
        }
        if titleLabel == nil { titleLabel = sorted.first }
        if bodyLabel == nil {
            bodyLabel = sorted.dropFirst().first ?? sorted.last
        }
    }

    @IBAction func allowAccessTapped(_ sender: Any) {
        view.window?.close()
        _ = AccessControlHelper.requestSystemPromptIfNeeded()
        // Help stays on demand from the menu — do not open a second window here.
    }
}

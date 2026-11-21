//
// ClipStatusItem — menu-bar status item with paused template variant (U27).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

enum ClipStatusItem {
    static var statusItemButtonImage = NSImage(named: NSImage.Name("StatusBarIcon"))

    static func create() -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = statusItemButtonImage
            button.image?.isTemplate = true
            button.setAccessibilityIdentifier(Accessibility.identifiers.statusItemButton)
            applyPausedAppearance(to: button, isPaused: false)
        }
        return statusItem
    }

    static func applyPausedAppearance(to button: NSStatusBarButton, isPaused: Bool) {
        button.setAccessibilityTitle(StatusItemPresentation.accessibilityTitle(isPaused: isPaused))
        button.setAccessibilityIdentifier(
            isPaused ? Accessibility.identifiers.statusItemPaused : Accessibility.identifiers.statusItemButton
        )
        // Prefer a distinct symbol when paused instead of dimming alpha (U27).
        if isPaused {
            button.image = NSImage(
                systemSymbolName: "pause.circle",
                accessibilityDescription: L10n.menuPauseCapture
            )
            button.image?.isTemplate = true
        } else {
            button.image = statusItemButtonImage
            button.image?.isTemplate = true
        }
    }
}

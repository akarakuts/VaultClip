//
// SettingsWindowController — programmatic 600pt settings window with toolbar tabs (U29).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

class SettingsWindowController: NSWindowController {
    private let tabs = SettingsTabViewController()

    static func createSettingsWindowController() -> SettingsWindowController {
        SettingsWindowController()
    }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.menuPreferences
        window.titleVisibility = .visible
        window.isReleasedWhenClosed = false
        window.setAccessibilityIdentifier(Accessibility.identifiers.settingsWindow)
        window.center()
        self.init(window: window)
        window.contentViewController = tabs
        window.setContentSize(NSSize(width: 600, height: 520))
    }

    func configure(state: State) {
        tabs.configure(state: state)
    }
}

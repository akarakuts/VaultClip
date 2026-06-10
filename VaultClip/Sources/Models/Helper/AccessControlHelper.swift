//
//  AccessControlHelper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import ApplicationServices
import AppKit
import Foundation

class AccessControlHelper {

    private static var hasShownSystemPromptThisSession = false
    private static var hasShownPasteBlockedAlertThisSession = false

    func isControlGranted() -> Bool {
        AXIsProcessTrusted()
    }

    /// When `showPopup` is true, the system dialog is shown at most once per app session.
    func isControlGranted(showPopup: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        guard showPopup else { return false }
        guard !Self.hasShownSystemPromptThisSession else { return false }
        Self.hasShownSystemPromptThisSession = true
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        return AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// In-app hint when paste is blocked — avoids hammering the system permission dialog.
    static func notifyPasteBlockedIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        guard !hasShownPasteBlockedAlertThisSession else { return }
        hasShownPasteBlockedAlertThisSession = true
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Accessibility permission required"
            alert.informativeText = """
            VaultClip needs Accessibility to paste into other apps with ⌘V.

            Open System Settings → Privacy & Security → Accessibility, enable VaultClip, then try again. \
            Install the app to /Applications and keep a single copy to avoid macOS resetting the permission.
            """
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                openAccessibilitySettings()
            }
        }
    }
}

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
import Security

class AccessControlHelper {

    private static var hasShownSystemPromptThisSession = false
    private static var hasShownAccessibilityNoticeThisSession = false
    private static var hasShownPasteBlockedAlertThisSession = false
    private static var hasShownWelcomeThisSession = false

    func isControlGranted() -> Bool {
        AXIsProcessTrusted()
    }

    /// When `showPopup` is true, the system dialog is shown at most once per app session.
    func isControlGranted(showPopup: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        guard showPopup else { return false }
        return Self.requestSystemPromptIfNeeded()
    }

    /// Single entry point for the macOS Accessibility permission sheet.
    @discardableResult
    static func requestSystemPromptIfNeeded() -> Bool {
        if AXIsProcessTrusted() { return true }
        guard !hasShownSystemPromptThisSession else { return false }
        hasShownSystemPromptThisSession = true
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        return AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    static func hasShownSystemPrompt() -> Bool {
        hasShownSystemPromptThisSession
    }

    /// Welcome / help onboarding — at most once per launch when permission is still missing.
    static func presentWelcomeIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        guard !hasShownWelcomeThisSession else { return }
        hasShownWelcomeThisSession = true
        Controller.main.welcomeWindowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Opens Accessibility settings and explains that a signed /Applications copy is required.
    static func notifyAccessibilityRequired(reason: AccessibilityNoticeReason = .general) {
        guard !hasShownAccessibilityNoticeThisSession else { return }
        hasShownAccessibilityNoticeThisSession = true
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L10n.accessibilityRequiredTitle
            var body = L10n.accessibilityRequiredBody
            if reason == .unsignedBuild {
                body += L10n.accessibilityRequiredUnsignedSuffix
            }
            alert.informativeText = body
            alert.addButton(withTitle: L10n.commonOpenSettings)
            alert.addButton(withTitle: L10n.commonOK)
            if alert.runModal() == .alertFirstButtonReturn {
                openAccessibilitySettings()
            }
        }
    }

    enum AccessibilityNoticeReason {
        case general
        case promptDeclined
        case unsignedBuild
    }

    /// True when the bundle fails code-signature validation (unsigned CI build before codesign-app.sh).
    static func isLikelyUnsignedBuild() -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &staticCode) == errSecSuccess,
              let staticCode else { return true }
        return SecStaticCodeCheckValidity(staticCode, SecCSFlags(rawValue: 0), nil) != errSecSuccess
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
            alert.messageText = L10n.accessibilityPasteBlockedTitle
            alert.informativeText = L10n.accessibilityPasteBlockedBody
            alert.addButton(withTitle: L10n.commonOpenSettings)
            alert.addButton(withTitle: L10n.commonOK)
            if alert.runModal() == .alertFirstButtonReturn {
                openAccessibilitySettings()
            }
        }
    }
}

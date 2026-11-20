//
// LaunchAtLoginHelper — SMAppService register/unregister for login items (macOS 14+).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import ServiceManagement

enum LaunchAtLoginHelper {

    private static let installedAppPath = "/Applications/VaultClip.app"

    /// Prefer the /Applications copy so login items and TCC stay stable across updates.
    static func canonicalAppPath() -> String {
        let current = (Bundle.main.bundlePath as NSString).standardizingPath
        let installed = (installedAppPath as NSString).standardizingPath
        if FileManager.default.fileExists(atPath: installed), current == installed {
            return installed
        }
        if FileManager.default.fileExists(atPath: installed), isTransientInstallPath(current) {
            return installed
        }
        return current
    }

    static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func enable() -> Bool {
        if isEnabled() { return true }
        return enableWithSMAppService()
    }

    @discardableResult
    static func disable() -> Bool {
        if !isEnabled() { return true }
        do {
            try SMAppService.mainApp.unregister()
            return SMAppService.mainApp.status != .enabled
        } catch {
            return false
        }
    }

    static func warnIfRunningFromTransientLocation() {
        let path = Bundle.main.bundlePath
        guard isTransientInstallPath(path) else { return }
        guard !UserDefaults.standard.bool(forKey: "didWarnTransientInstallPath") else { return }
        UserDefaults.standard.set(true, forKey: "didWarnTransientInstallPath")

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L10n.installTransientTitle
            alert.informativeText = L10n.installTransientBody
            alert.addButton(withTitle: L10n.commonOK)
            alert.runModal()
        }
    }

    private static func enableWithSMAppService() -> Bool {
        guard SMAppService.mainApp.status != .enabled else { return true }
        do {
            try SMAppService.mainApp.register()
        } catch {
            // Fall through to status check / approval alert.
        }
        switch SMAppService.mainApp.status {
        case .enabled:
            return true
        case .requiresApproval:
            presentRequiresApprovalAlert()
            return false
        default:
            return false
        }
    }

    private static func presentRequiresApprovalAlert() {
        DispatchQueue.main.async {
            PanelFocusGuard.withSuspended {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = L10n.launchAtLoginNeedsApprovalTitle
                alert.informativeText = L10n.launchAtLoginNeedsApprovalBody
                alert.addButton(withTitle: L10n.launchAtLoginOpenSettings)
                alert.addButton(withTitle: L10n.commonCancel)
                if alert.runModal() == .alertFirstButtonReturn {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        }
    }

    private static func isTransientInstallPath(_ path: String) -> Bool {
        path.hasPrefix("/Volumes/") || path.contains("/private/var/folders/") || path.contains("/.Trash/")
    }
}

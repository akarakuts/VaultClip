//
//  LaunchAtLoginHelper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
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
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return LoginServiceKit.isExistLoginItems(at: canonicalAppPath())
    }

    @discardableResult
    static func enable() -> Bool {
        if isEnabled() { return true }
        if #available(macOS 13.0, *) {
            return enableWithSMAppService()
        }
        pruneStaleLoginItems(keeping: canonicalAppPath())
        return LoginServiceKit.addLoginItems(at: canonicalAppPath())
    }

    @discardableResult
    static func disable() -> Bool {
        if !isEnabled() { return true }
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                return SMAppService.mainApp.status != .enabled
            } catch {
                return false
            }
        }
        pruneStaleLoginItems(keeping: "")
        return LoginServiceKit.removeLoginItems(at: canonicalAppPath())
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

    // MARK: - SMAppService (macOS 13+)

    @available(macOS 13.0, *)
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

    @available(macOS 13.0, *)
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

    // MARK: - Legacy LSSharedFileList (macOS 12)

    private static func pruneStaleLoginItems(keeping canonical: String) {
        if #available(macOS 13.0, *) { return }
        let keep = (canonical as NSString).standardizingPath
        for path in loginItemPaths() {
            let normalized = (path as NSString).standardizingPath
            guard normalized.hasSuffix("/VaultClip.app") else { continue }
            if keep.isEmpty || normalized != keep {
                LoginServiceKit.removeLoginItems(at: path)
            }
        }
    }

    private static func loginItemPaths() -> [String] {
        if #available(macOS 13.0, *) { return [] }
        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else {
            return []
        }
        let loginItemList = sharedFileList.takeRetainedValue()
        guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return [] }
        let items = snapshot.takeRetainedValue() as? [LSSharedFileListItem] ?? []
        return items.compactMap { item -> String? in
            guard let resolved = LSSharedFileListItemCopyResolvedURL(item, 0, nil) else { return nil }
            return (resolved.takeRetainedValue() as URL).path
        }
    }
}

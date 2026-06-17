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
            if SMAppService.mainApp.status == .enabled {
                return true
            }
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
        var success = true
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                do {
                    try SMAppService.mainApp.unregister()
                } catch {
                    success = false
                }
            }
        }
        pruneStaleLoginItems(keeping: "")
        if !LoginServiceKit.removeLoginItems(at: canonicalAppPath()) {
            success = false
        }
        return success
    }

    /// Drops login entries that point at old DMG paths or duplicate VaultClip.app copies.
    static func reconcile(wantsLaunchAtLogin: Bool) {
        if wantsLaunchAtLogin {
            _ = enable()
        } else {
            _ = disable()
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

  // MARK: - SMAppService (macOS 13+)

    @available(macOS 13.0, *)
    private static func enableWithSMAppService() -> Bool {
        removeAllLegacyLoginItems()
        guard SMAppService.mainApp.status != .enabled else { return true }
        do {
            try SMAppService.mainApp.register()
            return SMAppService.mainApp.status == .enabled
        } catch {
            pruneStaleLoginItems(keeping: canonicalAppPath())
            return LoginServiceKit.addLoginItems(at: canonicalAppPath())
        }
    }

    @available(macOS 13.0, *)
    private static func removeAllLegacyLoginItems() {
        pruneStaleLoginItems(keeping: "")
        _ = LoginServiceKit.removeLoginItems(at: canonicalAppPath())
        _ = LoginServiceKit.removeLoginItems(at: Bundle.main.bundlePath)
    }

    private static func isTransientInstallPath(_ path: String) -> Bool {
        path.hasPrefix("/Volumes/") || path.contains("/private/var/folders/") || path.contains("/.Trash/")
    }

    private static func pruneStaleLoginItems(keeping canonical: String) {
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

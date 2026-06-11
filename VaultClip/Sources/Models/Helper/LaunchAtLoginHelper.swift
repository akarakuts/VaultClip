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
import LoginServiceKit

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
        LoginServiceKit.isExistLoginItems(at: canonicalAppPath())
    }

    @discardableResult
    static func enable() -> Bool {
        pruneStaleLoginItems(keeping: canonicalAppPath())
        return LoginServiceKit.addLoginItems(at: canonicalAppPath())
    }

    @discardableResult
    static func disable() -> Bool {
        pruneStaleLoginItems(keeping: "")
        return LoginServiceKit.removeLoginItems(at: canonicalAppPath())
    }

    /// Drops login entries that point at old DMG paths or duplicate VaultClip.app copies.
    static func reconcile(wantsLaunchAtLogin: Bool) {
        let canonical = canonicalAppPath()
        pruneStaleLoginItems(keeping: wantsLaunchAtLogin ? canonical : "")

        let exists = LoginServiceKit.isExistLoginItems(at: canonical)
        if wantsLaunchAtLogin, !exists {
            LoginServiceKit.addLoginItems(at: canonical)
        } else if !wantsLaunchAtLogin, exists {
            LoginServiceKit.removeLoginItems(at: canonical)
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

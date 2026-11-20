//
// SourceAppDisplayName — cached display names for source bundle ids (U14).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Foundation

enum SourceAppDisplayName {
    private static var cache = [String: String]()
    private static let lock = NSLock()

    static func name(forBundleId bundleId: String?) -> String {
        guard let bundleId, !bundleId.isEmpty else {
            return L10n.filterUnknownSource
        }
        lock.lock()
        if let cached = cache[bundleId] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let resolved: String
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            resolved = FileManager.default.displayName(atPath: appURL.path)
        } else if let last = bundleId.split(separator: ".").last {
            resolved = String(last)
        } else {
            resolved = bundleId
        }

        lock.lock()
        cache[bundleId] = resolved
        lock.unlock()
        return resolved
    }
}

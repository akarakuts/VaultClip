//
//  SourceAppIconProvider.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Foundation

enum SourceAppIconProvider {
    
    private static var cache = [String: NSImage]()
    private static let lock = NSLock()
    
    static func icon(forBundleId bundleId: String?) -> NSImage {
        guard let bundleId = bundleId, !bundleId.isEmpty else {
            return unknownAppIcon
        }
        
        lock.lock()
        if let cached = cache[bundleId] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        let resolved: NSImage
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            resolved = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            resolved = unknownAppIcon
        }
        
        lock.lock()
        cache[bundleId] = resolved
        lock.unlock()
        return resolved
    }
    
    private static let unknownAppIcon: NSImage = {
        NSWorkspace.shared.icon(forFileType: "com.apple.application-bundle")
    }()
}

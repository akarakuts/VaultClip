//
//  AppDataMigrator.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum AppDataMigrator {

    static func migrateIfNeeded() {
        migrateApplicationSupportIfNeeded(from: Constants.branding.legacyBundleIdentifier)
        migrateApplicationSupportIfNeeded(from: "VaultClip")
        migrateUserDefaultsIfNeeded(from: Constants.branding.legacyBundleIdentifier)
        migrateUserDefaultsIfNeeded(from: "VaultClip")
    }

    private static func migrateApplicationSupportIfNeeded(from legacyFolder: String) {
        let fm = FileManager.default
        let legacy = Constants.urls.applicationSupport.appendingPathComponent(legacyFolder, isDirectory: true)
        let current = Constants.urls.appSupport

        guard fm.fileExists(atPath: legacy.path) else { return }
        guard !fm.fileExists(atPath: current.path) else { return }

        do {
            try fm.moveItem(at: legacy, to: current)
        } catch {
            #if DEBUG
            print("AppDataMigrator: failed to move Application Support from \(legacyFolder): \(error)")
            #endif
        }
    }

    private static func migrateUserDefaultsIfNeeded(from legacyDomain: String) {
        guard UserDefaults.standard.data(forKey: "settings") == nil else { return }
        guard let legacy = UserDefaults.standard.persistentDomain(forName: legacyDomain) else { return }

        if let settingsData = legacy["settings"] as? Data {
            UserDefaults.standard.set(settingsData, forKey: "settings")
        }
        for (key, value) in legacy where key != "settings" {
            if UserDefaults.standard.object(forKey: key) == nil {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
    }
}

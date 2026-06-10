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

    private static let didMigrateKey = "didMigrateFromMatthewDavidsonYippy"

    static func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didMigrateKey) else { return }
        migrateApplicationSupport()
        migrateUserDefaults()
        UserDefaults.standard.set(true, forKey: didMigrateKey)
    }

    private static func migrateApplicationSupport() {
        let fm = FileManager.default
        let legacy = Constants.urls.legacyAppSupport
        let current = Constants.urls.appSupport

        guard fm.fileExists(atPath: legacy.path) else { return }
        guard !fm.fileExists(atPath: current.path) else { return }

        do {
            try fm.moveItem(at: legacy, to: current)
        } catch {
            #if DEBUG
            print("AppDataMigrator: failed to move Application Support: \(error)")
            #endif
        }
    }

    private static func migrateUserDefaults() {
        guard UserDefaults.standard.data(forKey: "settings") == nil else { return }

        let legacyDomain = Constants.branding.legacyBundleIdentifier
        guard let legacy = UserDefaults.standard.persistentDomain(forName: legacyDomain),
              let settingsData = legacy["settings"] as? Data else {
            return
        }

        UserDefaults.standard.set(settingsData, forKey: "settings")
    }
}

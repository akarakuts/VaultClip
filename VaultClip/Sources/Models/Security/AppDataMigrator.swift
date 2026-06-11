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

    private static let keyFileName = ".history-encryption-key"

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

        if fm.fileExists(atPath: current.path) {
            mergeLegacySupport(from: legacy, into: current, fileManager: fm)
            return
        }

        do {
            try fm.moveItem(at: legacy, to: current)
        } catch {
            #if DEBUG
            print("AppDataMigrator: failed to move Application Support from \(legacyFolder): \(error)")
            #endif
        }
    }

    /// Copies a legacy encryption key and history when the current folder already exists.
    private static func mergeLegacySupport(from legacy: URL, into current: URL, fileManager: FileManager) {
        let legacyKey = legacy.appendingPathComponent(keyFileName, isDirectory: false)
        let currentKey = current.appendingPathComponent(keyFileName, isDirectory: false)

        if !fileManager.fileExists(atPath: currentKey.path),
           fileManager.fileExists(atPath: legacyKey.path) {
            try? fileManager.copyItem(at: legacyKey, to: currentKey)
        }

        let legacyHistory = legacy.appendingPathComponent("history", isDirectory: true)
        let currentHistory = current.appendingPathComponent("history", isDirectory: true)
        let currentHistoryEmpty = isHistoryDirectoryEmpty(at: currentHistory, fileManager: fileManager)
        let legacyHasHistory = fileManager.fileExists(atPath: legacyHistory.path)
            && !isHistoryDirectoryEmpty(at: legacyHistory, fileManager: fileManager)

        if currentHistoryEmpty, legacyHasHistory {
            if fileManager.fileExists(atPath: currentHistory.path) {
                try? fileManager.removeItem(at: currentHistory)
            }
            try? fileManager.copyItem(at: legacyHistory, to: currentHistory)
        }
    }

    private static func isHistoryDirectoryEmpty(at url: URL, fileManager: FileManager) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return true
        }
        return contents.isEmpty
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

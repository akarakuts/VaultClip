//
//  SymmetricKeyStore.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import CryptoKit
import Foundation

/// Persists the AES history key on disk (ad-hoc safe) and migrates legacy Keychain entries.
struct SymmetricKeyStore {

    static let `default` = SymmetricKeyStore()

    private static let keyFileName = ".history-encryption-key"
    private static let legacyKeychainServices = [
        Constants.branding.bundleIdentifier,
        "VaultClip",
        Constants.branding.legacyBundleIdentifier,
    ]

    private var keyFileURL: URL {
        Constants.urls.appSupport.appendingPathComponent(Self.keyFileName, isDirectory: false)
    }

    @discardableResult
    func loadOrCreateKey() throws -> SymmetricKey {
        if let fileKey = try loadFromFile() {
            return fileKey
        }
        for service in Self.legacyKeychainServices {
            let keychain = KeychainSymmetricKeyStore(service: service, account: "history-data-key")
            if let migrated = try keychain.loadExistingKey() {
                try saveToFile(migrated)
                return migrated
            }
        }
        let newKey = SymmetricKey(size: .bits256)
        try saveToFile(newKey)
        return newKey
    }

    private func loadFromFile() throws -> SymmetricKey? {
        let url = keyFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        guard data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    private func saveToFile(_ key: SymmetricKey) throws {
        let directory = keyFileURL.deletingLastPathComponent()
        try SecureStorageHelper.ensureSecureDirectory(at: directory)
        var data = key.withUnsafeBytes { Data($0) }
        defer { SecureStorageHelper.zeroize(&data) }
        try data.write(to: keyFileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: keyFileURL.path
        )
        var resourceURL = keyFileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try resourceURL.setResourceValues(values)
    }
}

enum EncryptionKeyBootstrap {

    private static var didPrepare = false

    static func prepareAtLaunch() {
        guard !didPrepare else { return }
        didPrepare = true
        do {
            _ = try SymmetricKeyStore.default.loadOrCreateKey()
        } catch {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "VaultClip cannot access its encryption key"
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: "Quit")
                alert.runModal()
                NSApp.terminate(nil)
            }
        }
    }
}

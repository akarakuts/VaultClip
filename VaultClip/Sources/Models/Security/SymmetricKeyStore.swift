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
import Security

enum SymmetricKeyStoreError: Error, LocalizedError {
    case keyMismatch
    case resetFailed(String)

    var errorDescription: String? {
        switch self {
        case .keyMismatch:
            return "Encrypted clipboard history was found, but no matching encryption key is available."
        case .resetFailed(let detail):
            return "Failed to reset encrypted history: \(detail)"
        }
    }
}

/// Probes on-disk history for VC1 payloads and validates candidate AES keys.
enum HistoryEncryptionProbe {

    static let encryptedPrefix = Data("VC1".utf8)

    static func hasEncryptedPayloads(fileManager: FileManager = .default) -> Bool {
        if isEncryptedFile(at: Constants.urls.historyOrder, fileManager: fileManager) {
            return true
        }
        guard let itemDirs = try? fileManager.contentsOfDirectory(
            at: Constants.urls.history,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }
        for itemDir in itemDirs {
            var isDirectory = ObjCBool(false)
            guard fileManager.fileExists(atPath: itemDir.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            guard let files = try? fileManager.contentsOfDirectory(
                at: itemDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            if files.contains(where: { isEncryptedFile(at: $0, fileManager: fileManager) }) {
                return true
            }
        }
        return false
    }

    static func isEncryptedFile(at url: URL, fileManager: FileManager = .default) -> Bool {
        guard fileManager.fileExists(atPath: url.path),
              let prefix = try? Data(contentsOf: url, options: [.mappedIfSafe]).prefix(encryptedPrefix.count),
              prefix == encryptedPrefix else {
            return false
        }
        return true
    }

    static func canDecrypt(with key: SymmetricKey, fileManager: FileManager = .default) -> Bool {
        guard let sample = firstEncryptedPayload(fileManager: fileManager) else {
            return true
        }
        do {
            let raw = try Data(contentsOf: sample)
            let ciphertext = raw.dropFirst(encryptedPrefix.count)
            let box = try AES.GCM.SealedBox(combined: Data(ciphertext))
            _ = try AES.GCM.open(box, using: key)
            return true
        } catch {
            return false
        }
    }

    private static func firstEncryptedPayload(fileManager: FileManager) -> URL? {
        if isEncryptedFile(at: Constants.urls.historyOrder, fileManager: fileManager) {
            return Constants.urls.historyOrder
        }
        guard let itemDirs = try? fileManager.contentsOfDirectory(
            at: Constants.urls.history,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        for itemDir in itemDirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            var isDirectory = ObjCBool(false)
            guard fileManager.fileExists(atPath: itemDir.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            guard let files = try? fileManager.contentsOfDirectory(
                at: itemDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            if let encrypted = files.first(where: { isEncryptedFile(at: $0, fileManager: fileManager) }) {
                return encrypted
            }
        }
        return nil
    }
}

/// Resolves the AES history key in Keychain; migrates legacy file and Keychain entries.
struct SymmetricKeyStore {

    static let `default` = SymmetricKeyStore()

    private static var cachedKey: SymmetricKey?

    private static let keyFileName = ".history-encryption-key"
    private static let legacyAppSupportFolders = [
        Constants.branding.bundleIdentifier,
        "VaultClip",
        Constants.branding.legacyBundleIdentifier,
    ]
    private static let legacyKeychainServices = [
        "VaultClip",
        Constants.branding.legacyBundleIdentifier,
    ]

    private let keychain = KeychainSymmetricKeyStore.default

    private var keyFileURL: URL {
        Constants.urls.appSupport.appendingPathComponent(Self.keyFileName, isDirectory: false)
    }

    @discardableResult
    func loadOrCreateKey() throws -> SymmetricKey {
        if let cachedKey = Self.cachedKey {
            return cachedKey
        }
        let key = try resolveKey()
        Self.cachedKey = key
        return key
    }

    @discardableResult
    private func resolveKey() throws -> SymmetricKey {
        let candidates = try collectKeyCandidates()
        let hasEncryptedHistory = HistoryEncryptionProbe.hasEncryptedPayloads()

        if hasEncryptedHistory {
            for candidate in candidates {
                if HistoryEncryptionProbe.canDecrypt(with: candidate.key) {
                    try persistResolvedKey(candidate.key)
                    return candidate.key
                }
            }
            throw SymmetricKeyStoreError.keyMismatch
        }

        if let keychainKey = try loadFromKeychainIfAvailable() {
            try removeMigratedKeyFiles()
            return keychainKey
        }

        if let candidate = candidates.first {
            try persistResolvedKey(candidate.key)
            return candidate.key
        }

        return try createNewKey()
    }

    static func clearCachedKey() {
        cachedKey = nil
    }

    func resetEncryptedHistoryAndCreateNewKey(fileManager: FileManager = .default) throws {
        if fileManager.fileExists(atPath: Constants.urls.history.path) {
            do {
                try fileManager.removeItem(at: Constants.urls.history)
            } catch {
                throw SymmetricKeyStoreError.resetFailed(error.localizedDescription)
            }
        }
        try? keychain.deleteStoredKey()
        try removeAllKeyFiles(fileManager: fileManager)
        try SecureStorageHelper.ensureSecureDirectory(at: Constants.urls.appSupport, fileManager: fileManager)
        try SecureStorageHelper.ensureSecureDirectory(at: Constants.urls.history, fileManager: fileManager)
        let newKey = try createNewKey()
        Self.cachedKey = newKey
    }

    private func createNewKey() throws -> SymmetricKey {
        if let key = try loadFromKeychainIfAvailable() {
            return key
        }
        do {
            let newKey = try keychain.loadOrCreateKey()
            try removeMigratedKeyFiles()
            return newKey
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            let newKey = SymmetricKey(size: .bits256)
            try saveToFile(newKey)
            return newKey
        }
    }

    private func persistResolvedKey(_ key: SymmetricKey) throws {
        do {
            try keychain.saveKey(key)
            try removeMigratedKeyFiles()
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            try saveToFile(key)
        }
    }

    private func loadFromKeychainIfAvailable() throws -> SymmetricKey? {
        do {
            return try keychain.loadExistingKey()
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            return nil
        }
    }

    private func collectKeyCandidates() throws -> [(source: String, key: SymmetricKey)] {
        var seen = Set<Data>()
        var result: [(String, SymmetricKey)] = []

        func append(_ key: SymmetricKey, source: String) {
            let data = key.withUnsafeBytes { Data($0) }
            guard seen.insert(data).inserted else { return }
            result.append((source, key))
        }

        if let key = try loadFromKeychainIfAvailable() {
            append(key, source: "keychain")
        }

        for service in Self.legacyKeychainServices {
            let legacy = KeychainSymmetricKeyStore(service: service, account: "history-data-key")
            do {
                if let key = try legacy.loadExistingKey() {
                    append(key, source: "keychain:\(service)")
                }
            } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
                continue
            }
        }

        if let key = try loadFromFile(at: keyFileURL) {
            append(key, source: "file")
        }

        for folder in Self.legacyAppSupportFolders {
            let url = Constants.urls.applicationSupport
                .appendingPathComponent(folder, isDirectory: true)
                .appendingPathComponent(Self.keyFileName, isDirectory: false)
            if let key = try loadFromFile(at: url) {
                append(key, source: "file:\(folder)")
            }
        }

        return result
    }

    private func loadFromFile(at url: URL) throws -> SymmetricKey? {
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

    private func removeMigratedKeyFiles(fileManager: FileManager = .default) throws {
        try removeAllKeyFiles(fileManager: fileManager)
    }

    private func removeAllKeyFiles(fileManager: FileManager = .default) throws {
        let urls = [keyFileURL] + Self.legacyAppSupportFolders.map {
            Constants.urls.applicationSupport
                .appendingPathComponent($0, isDirectory: true)
                .appendingPathComponent(Self.keyFileName, isDirectory: false)
        }
        for url in urls where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}

enum EncryptionKeyBootstrap {

    private static var didPrepare = false

    static func prepareAtLaunch() {
        guard !didPrepare else { return }
        didPrepare = true
        do {
            _ = try SymmetricKeyStore.default.loadOrCreateKey()
        } catch SymmetricKeyStoreError.keyMismatch {
            showKeyMismatchAlert()
        } catch KeychainSymmetricKeyStore.KeychainError.osStatus(let status) {
            showKeychainFatalAlert(status: status)
        } catch {
            showFatalAlert(error)
        }
    }

    private static func showKeyMismatchAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.encryptionDecryptTitle
        alert.informativeText = L10n.encryptionDecryptBody
        alert.addButton(withTitle: L10n.commonStartFresh)
        alert.addButton(withTitle: L10n.commonQuit)
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                SymmetricKeyStore.clearCachedKey()
                try SymmetricKeyStore.default.resetEncryptedHistoryAndCreateNewKey()
                _ = try SymmetricKeyStore.default.loadOrCreateKey()
            } catch {
                showFatalAlert(error)
            }
            return
        }
        NSApp.terminate(nil)
    }

    private static func showKeychainFatalAlert(status: OSStatus) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = L10n.encryptionKeyTitle
        alert.informativeText = keychainErrorMessage(for: status)
        alert.addButton(withTitle: L10n.commonOpenKeychainAccess)
        alert.addButton(withTitle: L10n.commonQuit)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Utilities/Keychain Access.app"))
        }
        NSApp.terminate(nil)
    }

    private static func showFatalAlert(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = L10n.encryptionKeyTitle
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: L10n.commonQuit)
        alert.runModal()
        NSApp.terminate(nil)
    }

    private static func keychainErrorMessage(for status: OSStatus) -> String {
        let account = KeychainSymmetricKeyStore.default.account
        if status == errSecInteractionNotAllowed {
            return L10n.encryptionKeychainUnlock
        }
        if status == errSecAuthFailed {
            return L10n.encryptionKeychainDenied(account: account)
        }
        if status == errSecMissingEntitlement {
            return L10n.encryptionKeychainEntitlement(status: status)
        }
        return L10n.encryptionKeychainGeneric(status: status)
    }
}

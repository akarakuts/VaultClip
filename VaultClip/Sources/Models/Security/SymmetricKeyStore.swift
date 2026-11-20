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
              let handle = FileHandle(forReadingAtPath: url.path) else {
            return false
        }
        // Read only the magic prefix — never the whole (possibly multi-MB) payload file.
        defer { try? handle.close() }
        let prefix = handle.readData(ofLength: encryptedPrefix.count)
        return prefix == encryptedPrefix
    }

    static func canDecrypt(with key: SymmetricKey, fileManager: FileManager = .default) -> Bool {
        decryptableSampleCount(with: key, fileManager: fileManager) > 0
            || samplePayloads(limit: 1, fileManager: fileManager).isEmpty
    }

    /// Up to `limit` encrypted data files from distinct item directories (sorted by name), plus `order.xml` when encrypted.
    static func samplePayloads(limit: Int = 8, fileManager: FileManager = .default) -> [URL] {
        var samples: [URL] = []
        guard let itemDirs = try? fileManager.contentsOfDirectory(
            at: Constants.urls.history,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            if isEncryptedFile(at: Constants.urls.historyOrder, fileManager: fileManager) {
                return [Constants.urls.historyOrder]
            }
            return []
        }
        for itemDir in itemDirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard samples.count < limit else { break }
            var isDirectory = ObjCBool(false)
            guard fileManager.fileExists(atPath: itemDir.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            guard let files = try? fileManager.contentsOfDirectory(
                at: itemDir,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            let dataFiles = files
                .filter { !HistoryItem.isMetadataFileName($0.lastPathComponent) }
                .filter { isEncryptedFile(at: $0, fileManager: fileManager) }
                .sorted { lhs, rhs in
                    let ls = (try? lhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? Int.max
                    let rs = (try? rhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? Int.max
                    return ls < rs
                }
            if let smallest = dataFiles.first {
                samples.append(smallest)
            }
        }
        if isEncryptedFile(at: Constants.urls.historyOrder, fileManager: fileManager) {
            samples.append(Constants.urls.historyOrder)
        }
        return samples
    }

    static func decryptableSampleCount(with key: SymmetricKey, fileManager: FileManager = .default) -> Int {
        var count = 0
        for sample in samplePayloads(limit: 8, fileManager: fileManager) {
            do {
                let raw = try Data(contentsOf: sample)
                let ciphertext = raw.dropFirst(encryptedPrefix.count)
                let box = try AES.GCM.SealedBox(combined: Data(ciphertext))
                _ = try AES.GCM.open(box, using: key)
                count += 1
            } catch {
                continue
            }
        }
        return count
    }
}

/// Keychain adapter for `KeyResolver`.
struct KeychainEncryptionKeyBackend: EncryptionKeyBackend {
    let store: KeychainSymmetricKeyStore
    let sourceName: String

    init(store: KeychainSymmetricKeyStore = .default, sourceName: String = "keychain") {
        self.store = store
        self.sourceName = sourceName
    }

    func loadExistingKey() throws -> SymmetricKey? {
        try store.loadExistingKey()
    }

    func saveKey(_ key: SymmetricKey) throws {
        try store.saveKey(key)
    }

    func deleteStoredKey() throws {
        try store.deleteStoredKey()
    }
}

/// File-backed AES key next to Application Support data (ad-hoc / missing entitlement fallback).
struct FileEncryptionKeyBackend: EncryptionKeyBackend {
    let url: URL
    let sourceName: String

    func loadExistingKey() throws -> SymmetricKey? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        guard data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    func saveKey(_ key: SymmetricKey) throws {
        let directory = url.deletingLastPathComponent()
        try SecureStorageHelper.ensureSecureDirectory(at: directory)
        var data = key.withUnsafeBytes { Data($0) }
        defer { SecureStorageHelper.zeroize(&data) }
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: url.path
        )
        var resourceURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try resourceURL.setResourceValues(values)
    }

    func deleteStoredKey() throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

/// Resolves the AES history key in Keychain; migrates legacy file and Keychain entries.
struct SymmetricKeyStore {

    static let `default` = SymmetricKeyStore()

    private static var cachedKey: SymmetricKey?
    private static let cachedKeyLock = NSLock()

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
        Self.cachedKeyLock.lock()
        if let cachedKey = Self.cachedKey {
            Self.cachedKeyLock.unlock()
            return cachedKey
        }
        Self.cachedKeyLock.unlock()
        let key = try makeResolver().resolve().key
        Self.cachedKeyLock.lock()
        Self.cachedKey = key
        Self.cachedKeyLock.unlock()
        return key
    }

    static func clearCachedKey() {
        cachedKeyLock.lock()
        cachedKey = nil
        cachedKeyLock.unlock()
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
        let newKey = try makeResolver().resolve().key
        Self.cachedKeyLock.lock()
        Self.cachedKey = newKey
        Self.cachedKeyLock.unlock()
    }

    private func makeResolver() -> KeyResolver {
        let primary = KeychainEncryptionKeyBackend(store: keychain, sourceName: "keychain")
        let file = FileEncryptionKeyBackend(url: keyFileURL, sourceName: "file")
        var legacy: [EncryptionKeyBackend] = []
        if AppIdentity.isProduction {
            for service in Self.legacyKeychainServices {
                let store = KeychainSymmetricKeyStore(service: service, account: "history-data-key")
                legacy.append(KeychainEncryptionKeyBackend(store: store, sourceName: "keychain:\(service)"))
            }
            for folder in Self.legacyAppSupportFolders {
                let url = Constants.urls.applicationSupport
                    .appendingPathComponent(folder, isDirectory: true)
                    .appendingPathComponent(Self.keyFileName, isDirectory: false)
                legacy.append(FileEncryptionKeyBackend(url: url, sourceName: "file:\(folder)"))
            }
        }
        return KeyResolver(
            probe: KeyResolverProbe(
                hasEncryptedHistory: { HistoryEncryptionProbe.hasEncryptedPayloads() },
                decryptableSampleCount: { HistoryEncryptionProbe.decryptableSampleCount(with: $0) },
                samplePayloadCount: { HistoryEncryptionProbe.samplePayloads().count }
            ),
            primaryKeychain: primary,
            fileBackend: file,
            legacyBackends: legacy,
            createFileFallbackKey: {
                let newKey = SymmetricKey(size: .bits256)
                try file.saveKey(newKey)
                return newKey
            },
            createKeychainKey: {
                try self.keychain.loadOrCreateKey()
            }
        )
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

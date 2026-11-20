//
// KeyResolver — pure AES key selection among Keychain / file / legacy backends (T39).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CryptoKit
import Foundation
import Security

/// Read/write surface for one key storage backend used by `KeyResolver`.
protocol EncryptionKeyBackend {
    var sourceName: String { get }
    func loadExistingKey() throws -> SymmetricKey?
    func saveKey(_ key: SymmetricKey) throws
    func deleteStoredKey() throws
}

/// Probe callbacks keep disk I/O out of the resolver so unit tests can drive the matrix.
struct KeyResolverProbe {
    var hasEncryptedHistory: () -> Bool
    var decryptableSampleCount: (SymmetricKey) -> Int
    var samplePayloadCount: () -> Int
}

/// Chooses the AES history key: decrypt-score among candidates, migrate to Keychain when possible.
struct KeyResolver {

    var probe: KeyResolverProbe
    var primaryKeychain: EncryptionKeyBackend
    var fileBackend: EncryptionKeyBackend
    var legacyBackends: [EncryptionKeyBackend]
    /// Invoked when Keychain create fails with `errSecMissingEntitlement`.
    var createFileFallbackKey: () throws -> SymmetricKey
    var createKeychainKey: () throws -> SymmetricKey

    func collectCandidates() throws -> [(source: String, key: SymmetricKey)] {
        var seen = Set<Data>()
        var result: [(String, SymmetricKey)] = []

        func append(_ key: SymmetricKey, source: String) {
            let data = key.withUnsafeBytes { Data($0) }
            guard seen.insert(data).inserted else { return }
            result.append((source, key))
        }

        if let key = try loadIgnoringMissingEntitlement(from: primaryKeychain) {
            append(key, source: primaryKeychain.sourceName)
        }
        for backend in legacyBackends {
            if let key = try loadIgnoringMissingEntitlement(from: backend) {
                append(key, source: backend.sourceName)
            }
        }
        if let key = try fileBackend.loadExistingKey() {
            append(key, source: fileBackend.sourceName)
        }
        return result
    }

    func resolve() throws -> (source: String, key: SymmetricKey) {
        let candidates = try collectCandidates()
        let hasEncryptedHistory = probe.hasEncryptedHistory()

        if hasEncryptedHistory {
            var best: (source: String, key: SymmetricKey, score: Int)?
            for candidate in candidates {
                let score = probe.decryptableSampleCount(candidate.key)
                if let current = best {
                    if score > current.score {
                        best = (candidate.source, candidate.key, score)
                    } else if score == current.score, score > 0, candidate.source == primaryKeychain.sourceName {
                        best = (candidate.source, candidate.key, score)
                    }
                } else if score > 0 {
                    best = (candidate.source, candidate.key, score)
                }
            }
            guard let best, best.score > 0 else {
                throw SymmetricKeyStoreError.keyMismatch
            }
            let totalSamples = probe.samplePayloadCount()
            if best.score < totalSamples {
                ClipWarning(localizedDescription: "Encryption key decrypts \(best.score)/\(totalSamples) sample payloads; remaining items will be quarantined.")
                    .log(with: WarningLogger.general)
            }
            try persistResolvedKey(best.key)
            return (best.source, best.key)
        }

        if let keychainKey = try loadIgnoringMissingEntitlement(from: primaryKeychain) {
            try? fileBackend.deleteStoredKey()
            for backend in legacyBackends {
                try? backend.deleteStoredKey()
            }
            return (primaryKeychain.sourceName, keychainKey)
        }

        if let candidate = candidates.first {
            try persistResolvedKey(candidate.key)
            return (candidate.source, candidate.key)
        }

        return try createNewKey()
    }

    private func createNewKey() throws -> (source: String, key: SymmetricKey) {
        if let key = try loadIgnoringMissingEntitlement(from: primaryKeychain) {
            return (primaryKeychain.sourceName, key)
        }
        do {
            let newKey = try createKeychainKey()
            try? fileBackend.deleteStoredKey()
            for backend in legacyBackends {
                try? backend.deleteStoredKey()
            }
            return (primaryKeychain.sourceName, newKey)
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            let newKey = try createFileFallbackKey()
            return (fileBackend.sourceName, newKey)
        }
    }

    private func persistResolvedKey(_ key: SymmetricKey) throws {
        do {
            try primaryKeychain.saveKey(key)
            try? fileBackend.deleteStoredKey()
            for backend in legacyBackends {
                try? backend.deleteStoredKey()
            }
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            try fileBackend.saveKey(key)
        }
    }

    private func loadIgnoringMissingEntitlement(from backend: EncryptionKeyBackend) throws -> SymmetricKey? {
        do {
            return try backend.loadExistingKey()
        } catch let KeychainSymmetricKeyStore.KeychainError.osStatus(status) where status == errSecMissingEntitlement {
            return nil
        }
    }
}

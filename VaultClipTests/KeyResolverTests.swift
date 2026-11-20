//
// KeyResolverTests — matrix of encryption key selection paths (T39).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CryptoKit
import XCTest
@testable import VaultClip

private final class MemoryKeyBackend: EncryptionKeyBackend {
    let sourceName: String
    var key: SymmetricKey?
    var saveCalls = 0
    var deleteCalls = 0
    var saveError: Error?
    var loadError: Error?

    init(sourceName: String, key: SymmetricKey? = nil) {
        self.sourceName = sourceName
        self.key = key
    }

    func loadExistingKey() throws -> SymmetricKey? {
        if let loadError { throw loadError }
        return key
    }

    func saveKey(_ key: SymmetricKey) throws {
        if let saveError { throw saveError }
        saveCalls += 1
        self.key = key
    }

    func deleteStoredKey() throws {
        deleteCalls += 1
        key = nil
    }
}

final class KeyResolverTests: XCTestCase {

    private func key(_ seed: UInt8) -> SymmetricKey {
        SymmetricKey(data: Data(repeating: seed, count: 32))
    }

    private func resolver(
        hasHistory: Bool,
        scores: [Data: Int] = [:],
        sampleCount: Int = 0,
        keychain: MemoryKeyBackend,
        file: MemoryKeyBackend,
        legacy: [MemoryKeyBackend] = [],
        createFileFallback: SymmetricKey? = nil,
        createKeychainThrowsMissingEntitlement: Bool = false
    ) -> KeyResolver {
        let scoreLookup: (SymmetricKey) -> Int = { k in
            let data = k.withUnsafeBytes { Data($0) }
            return scores[data] ?? 0
        }
        return KeyResolver(
            probe: KeyResolverProbe(
                hasEncryptedHistory: { hasHistory },
                decryptableSampleCount: scoreLookup,
                samplePayloadCount: { sampleCount }
            ),
            primaryKeychain: keychain,
            fileBackend: file,
            legacyBackends: legacy,
            createFileFallbackKey: {
                let k = createFileFallback ?? SymmetricKey(size: .bits256)
                try file.saveKey(k)
                return k
            },
            createKeychainKey: {
                if createKeychainThrowsMissingEntitlement {
                    throw KeychainSymmetricKeyStore.KeychainError.osStatus(errSecMissingEntitlement)
                }
                let k = SymmetricKey(size: .bits256)
                try keychain.saveKey(k)
                return k
            }
        )
    }

    func testNoHistoryNoKeyCreatesNew() throws {
        let keychain = MemoryKeyBackend(sourceName: "keychain")
        let file = MemoryKeyBackend(sourceName: "file")
        let resolved = try resolver(hasHistory: false, keychain: keychain, file: file).resolve()
        XCTAssertEqual(resolved.source, "keychain")
        XCTAssertNotNil(keychain.key)
    }

    func testHistoryMatchingKeychainWins() throws {
        let matching = key(1)
        let keychain = MemoryKeyBackend(sourceName: "keychain", key: matching)
        let file = MemoryKeyBackend(sourceName: "file", key: key(2))
        let data = matching.withUnsafeBytes { Data($0) }
        let resolved = try resolver(
            hasHistory: true,
            scores: [data: 3],
            sampleCount: 3,
            keychain: keychain,
            file: file
        ).resolve()
        XCTAssertEqual(resolved.source, "keychain")
        XCTAssertEqual(keychain.saveCalls, 1)
        XCTAssertEqual(file.deleteCalls, 1)
    }

    func testLegacyFileMigratesToKeychainAndDeletesFile() throws {
        let legacyKey = key(7)
        let keychain = MemoryKeyBackend(sourceName: "keychain")
        let file = MemoryKeyBackend(sourceName: "file", key: legacyKey)
        let data = legacyKey.withUnsafeBytes { Data($0) }
        let resolved = try resolver(
            hasHistory: true,
            scores: [data: 2],
            sampleCount: 2,
            keychain: keychain,
            file: file
        ).resolve()
        XCTAssertEqual(resolved.source, "file")
        XCTAssertEqual(keychain.saveCalls, 1)
        XCTAssertNil(file.key)
        XCTAssertEqual(file.deleteCalls, 1)
    }

    func testNoCandidateDecryptsThrowsMismatch() {
        let keychain = MemoryKeyBackend(sourceName: "keychain", key: key(1))
        let file = MemoryKeyBackend(sourceName: "file", key: key(2))
        XCTAssertThrowsError(
            try resolver(hasHistory: true, scores: [:], sampleCount: 2, keychain: keychain, file: file).resolve()
        ) { error in
            guard case SymmetricKeyStoreError.keyMismatch = error else {
                return XCTFail("expected keyMismatch, got \(error)")
            }
        }
    }

    func testMissingEntitlementFallsBackToFile() throws {
        let keychain = MemoryKeyBackend(sourceName: "keychain")
        keychain.loadError = KeychainSymmetricKeyStore.KeychainError.osStatus(errSecMissingEntitlement)
        keychain.saveError = KeychainSymmetricKeyStore.KeychainError.osStatus(errSecMissingEntitlement)
        let file = MemoryKeyBackend(sourceName: "file")
        let fallback = key(9)
        let resolved = try resolver(
            hasHistory: false,
            keychain: keychain,
            file: file,
            createFileFallback: fallback,
            createKeychainThrowsMissingEntitlement: true
        ).resolve()
        XCTAssertEqual(resolved.source, "file")
        XCTAssertEqual(file.saveCalls, 1)
    }

    func testMultipleCandidatesPickHighestDecryptScore() throws {
        let weakKey = key(1)
        let strongKey = key(2)
        let keychain = MemoryKeyBackend(sourceName: "keychain", key: weakKey)
        let file = MemoryKeyBackend(sourceName: "file", key: strongKey)
        let weakData = weakKey.withUnsafeBytes { Data($0) }
        let strongData = strongKey.withUnsafeBytes { Data($0) }
        let resolved = try resolver(
            hasHistory: true,
            scores: [weakData: 1, strongData: 4],
            sampleCount: 4,
            keychain: keychain,
            file: file
        ).resolve()
        XCTAssertEqual(resolved.source, "file")
        let resolvedData = resolved.key.withUnsafeBytes { Data($0) }
        XCTAssertEqual(resolvedData, strongData)
    }
}

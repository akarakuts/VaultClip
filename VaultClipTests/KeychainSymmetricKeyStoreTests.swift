//
// KeychainSymmetricKeyStoreTests — round-trip AES key save/load/delete (coverage gate).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CryptoKit
import XCTest
@testable import VaultClip

final class KeychainSymmetricKeyStoreTests: XCTestCase {

    private var store: KeychainSymmetricKeyStore!

    override func setUp() {
        super.setUp()
        store = KeychainSymmetricKeyStore(
            service: "com.karakuts.VaultClip.tests.keychain.\(UUID().uuidString)",
            account: "history-data-key-test"
        )
        try? store.deleteStoredKey()
    }

    override func tearDown() {
        try? store.deleteStoredKey()
        store = nil
        super.tearDown()
    }

    func testLoadMissingReturnsNil() throws {
        XCTAssertNil(try store.loadExistingKey())
    }

    func testSaveLoadRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        try store.saveKey(key)
        let loaded = try store.loadExistingKey()
        XCTAssertNotNil(loaded)
        let original = key.withUnsafeBytes { Data($0) }
        let roundTrip = loaded!.withUnsafeBytes { Data($0) }
        XCTAssertEqual(original, roundTrip)
    }

    func testSaveOverwritesDuplicate() throws {
        let first = SymmetricKey(size: .bits256)
        let second = SymmetricKey(size: .bits256)
        try store.saveKey(first)
        try store.saveKey(second)
        let loaded = try store.loadExistingKey()
        let expected = second.withUnsafeBytes { Data($0) }
        let actual = loaded!.withUnsafeBytes { Data($0) }
        XCTAssertEqual(expected, actual)
    }

    func testDeleteRemovesKey() throws {
        try store.saveKey(SymmetricKey(size: .bits256))
        try store.deleteStoredKey()
        XCTAssertNil(try store.loadExistingKey())
    }

    func testLoadOrCreatePersists() throws {
        let created = try store.loadOrCreateKey()
        let again = try store.loadOrCreateKey()
        let a = created.withUnsafeBytes { Data($0) }
        let b = again.withUnsafeBytes { Data($0) }
        XCTAssertEqual(a, b)
    }
}

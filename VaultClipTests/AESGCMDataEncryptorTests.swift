//
//  AESGCMDataEncryptorTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
import CryptoKit
@testable import VaultClip

final class AESGCMDataEncryptorTests: XCTestCase {

    // Uses the shared key store (read-only key resolution). These tests never delete
    // or rotate `history-data-key` — that would permanently break existing history.

    func testEncryptDecryptRoundTrip() throws {
        let encryptor = AESGCMDataEncryptor()
        let payload = Data("VaultClip sealed-box check 📋".utf8)

        let sealed = try encryptor.encrypt(payload)
        XCTAssertNotEqual(sealed, payload)
        let opened = try encryptor.decrypt(sealed)
        XCTAssertEqual(opened, payload)
    }

    func testEncryptsProduceDistinctCiphertexts() throws {
        let encryptor = AESGCMDataEncryptor()
        let payload = Data("same input".utf8)
        let first = try encryptor.encrypt(payload)
        let second = try encryptor.encrypt(payload)
        XCTAssertNotEqual(first, second, "nonce reuse across writes")
    }

    func testDecryptTamperedDataThrows() throws {
        let encryptor = AESGCMDataEncryptor()
        var sealed = try encryptor.encrypt(Data("original".utf8))
        sealed[sealed.count - 1] ^= 0xFF
        XCTAssertThrowsError(try encryptor.decrypt(sealed))
    }

    func testDecryptDataSealedWithOtherKeyThrows() throws {
        let encryptor = AESGCMDataEncryptor()
        let foreignKey = SymmetricKey(size: .bits256)
        let sealed = try AES.GCM.seal(Data("secret".utf8), using: foreignKey)
        let combined = try XCTUnwrap(sealed.combined)
        XCTAssertThrowsError(try encryptor.decrypt(combined))
    }

    func testEmptyDataRoundTrip() throws {
        let encryptor = AESGCMDataEncryptor()
        let sealed = try encryptor.encrypt(Data())
        XCTAssertEqual(try encryptor.decrypt(sealed), Data())
    }
}

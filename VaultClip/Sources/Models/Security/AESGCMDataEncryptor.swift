//
//  AESGCMDataEncryptor.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import CryptoKit

final class AESGCMDataEncryptor: DataEncryptor {

    private let keyStore: SymmetricKeyStore

    init(keyStore: SymmetricKeyStore = .default) {
        self.keyStore = keyStore
    }

    func encrypt(_ data: Data) throws -> Data {
        let key = try keyStore.loadOrCreateKey()
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw DataEncryptionError.failedToSeal
        }
        return combined
    }

    func decrypt(_ data: Data) throws -> Data {
        let key = try keyStore.loadOrCreateKey()
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }
}

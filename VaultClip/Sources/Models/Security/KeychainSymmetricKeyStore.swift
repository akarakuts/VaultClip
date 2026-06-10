//
//  KeychainSymmetricKeyStore.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import CryptoKit
import Foundation
import Security

/// Legacy Keychain storage — used only to migrate keys into the on-disk store.
struct KeychainSymmetricKeyStore {

    enum KeychainError: Error {
        case osStatus(OSStatus)
    }

    let service: String
    let account: String

    func loadExistingKey() throws -> SymmetricKey? {
        try load(service: service)
    }

    private func lookupQuery(service: String, returnData: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
        return query
    }

    private func load(service: String) throws -> SymmetricKey? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(lookupQuery(service: service, returnData: true) as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        case errSecInteractionNotAllowed:
            // Keychain locked (before first unlock) — surface to caller for a user prompt path.
            throw KeychainError.osStatus(status)
        default:
            throw KeychainError.osStatus(status)
        }
    }

}

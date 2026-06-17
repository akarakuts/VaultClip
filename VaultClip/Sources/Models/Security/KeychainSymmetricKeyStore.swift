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

/// AES history key in macOS Keychain (generic password).
struct KeychainSymmetricKeyStore {

    enum KeychainError: Error {
        case osStatus(OSStatus)
    }

    static let legacyService = Constants.branding.legacyBundleIdentifier

    static let `default` = KeychainSymmetricKeyStore(
        service: Constants.branding.bundleIdentifier,
        account: "history-data-key"
    )

    let service: String
    let account: String

    func loadExistingKey() throws -> SymmetricKey? {
        try load(service: service)
    }

    @discardableResult
    func loadOrCreateKey() throws -> SymmetricKey {
        do {
            return try performLoadOrCreate()
        } catch KeychainError.osStatus(errSecMissingEntitlement) {
            // Item left by a build that used SecAccessControl without proper signing.
            try deleteKey(service: service)
            return try performLoadOrCreate()
        }
    }

    func saveKey(_ key: SymmetricKey) throws {
        try save(key, service: service)
    }

    func deleteStoredKey() throws {
        try deleteKey(service: service)
    }

    private func performLoadOrCreate() throws -> SymmetricKey {
        if let existing = try load(service: service) {
            return existing
        }
        if service == Self.default.service,
           let legacy = try load(service: Self.legacyService) {
            try save(legacy, service: service)
            return legacy
        }
        let new = SymmetricKey(size: .bits256)
        try save(new, service: service)
        return new
    }

    private func deleteKey(service: String) throws {
        let status = SecItemDelete(lookupQuery(service: service, returnData: false) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osStatus(status)
        }
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
            throw KeychainError.osStatus(status)
        default:
            throw KeychainError.osStatus(status)
        }
    }

    private func save(_ key: SymmetricKey, service: String) throws {
        let data = key.withUnsafeBytes { Data($0) }
        // Plain accessibility only — SecAccessControl/userPresence needs Developer ID
        // and breaks ad-hoc/GitHub DMG builds (errSecMissingEntitlement).
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
        ]

        var status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updates: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]
            status = SecItemUpdate(lookupQuery(service: service, returnData: false) as CFDictionary, updates as CFDictionary)
        }
        guard status == errSecSuccess else {
            throw KeychainError.osStatus(status)
        }
    }
}

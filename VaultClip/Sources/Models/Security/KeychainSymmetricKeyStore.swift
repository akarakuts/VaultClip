//
//  KeychainSymmetricKeyStore.swift
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

    /// Ensures the encryption key exists before history I/O. Call once at launch.
    @discardableResult
    func loadOrCreateKey() throws -> SymmetricKey {
        if let existing = try load(service: service) {
            return existing
        }
        if let legacy = try load(service: Self.legacyService) {
            try save(legacy, service: service)
            return legacy
        }
        let new = SymmetricKey(size: .bits256)
        try save(new, service: service)
        return new
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

    private func save(_ key: SymmetricKey, service: String) throws {
        let data = key.withUnsafeBytes { Data($0) }
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
        ]

        // Require user authentication when the key is read (Touch ID / login password).
        var accessError: Unmanaged<CFError>?
        if let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            .userPresence,
            &accessError
        ) {
            attributes[kSecAttrAccessControl as String] = access
        }

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

enum EncryptionKeyBootstrap {

    private static var didPrepare = false

    /// Loads or creates the history encryption key; shows an alert if Keychain denies access.
    static func prepareAtLaunch() {
        guard !didPrepare else { return }
        didPrepare = true
        do {
            _ = try KeychainSymmetricKeyStore.default.loadOrCreateKey()
        } catch KeychainSymmetricKeyStore.KeychainError.osStatus(let status) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "VaultClip cannot access its encryption key"
                alert.informativeText = keychainErrorMessage(for: status)
                alert.addButton(withTitle: "Open Keychain Access")
                alert.addButton(withTitle: "Quit")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Utilities/Keychain Access.app"))
                }
                NSApp.terminate(nil)
            }
        } catch {
            DispatchQueue.main.async {
                NSAlert(error: error).runModal()
            }
        }
    }

    private static func keychainErrorMessage(for status: OSStatus) -> String {
        if status == errSecInteractionNotAllowed {
            return "Unlock your Mac and try again. VaultClip needs Keychain access to read encrypted clipboard history."
        }
        if status == errSecAuthFailed {
            return "Keychain denied access to the encryption key. Open Keychain Access, find the entry \"\(KeychainSymmetricKeyStore.default.account)\" for VaultClip, and allow access for this application."
        }
        return "Keychain error (\(status)). Encrypted history cannot be read or saved until access is granted."
    }
}

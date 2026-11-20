//
//  DataFileManager.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import CryptoKit
import Foundation

enum StoredDataError: Error {
    case authenticationFailed
    case unreadable(Error)
}

class DataFileManager {

    /// Prefix for encrypted payloads written after the VaultClip security upgrade.
    private static let encryptedPrefix = Data("VC1".utf8)

    private let encryptor: DataEncryptor

    init(encryptor: DataEncryptor = AESGCMDataEncryptor()) {
        self.encryptor = encryptor
    }

    func loadData(contentsOf url: URL) throws -> Data {
        let raw: Data
        do {
            raw = try Data(contentsOf: url)
        } catch {
            throw StoredDataError.unreadable(error)
        }
        guard raw.starts(with: Self.encryptedPrefix) else {
            // Legacy plaintext written before encryption — returned as-is; next write re-encrypts.
            return raw
        }
        let ciphertext = Data(raw.dropFirst(Self.encryptedPrefix.count))
        do {
            return try encryptor.decrypt(ciphertext)
        } catch {
            if Self.isAuthenticationFailure(error) {
                throw StoredDataError.authenticationFailed
            }
            throw StoredDataError.unreadable(error)
        }
    }

    func writeData(_ data: Data, to url: URL, options: Data.WritingOptions = .atomic) throws {
        let payload = try encryptor.encrypt(data)
        var wrapped = Self.encryptedPrefix
        wrapped.append(payload)
        try wrapped.write(to: url, options: options)
        try? FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: url.path
        )
    }

    /// Re-encrypts legacy plaintext files on read when persisting again.
    func migrateLegacyFileIfNeeded(at url: URL) {
        guard let raw = try? Data(contentsOf: url), !raw.starts(with: Self.encryptedPrefix) else { return }
        try? writeData(raw, to: url, options: .atomic)
    }

    static func isAuthenticationFailure(_ error: Error) -> Bool {
        if case StoredDataError.authenticationFailed = error {
            return true
        }
        if let crypto = error as? CryptoKitError {
            if case .authenticationFailure = crypto { return true }
            if case .incorrectParameterSize = crypto { return true }
        }
        return (error as NSError).domain.contains("CryptoKit")
    }
}

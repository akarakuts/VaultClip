//
//  DataFileManager.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class DataFileManager {

    /// Prefix for encrypted payloads written after the VaultClip security upgrade.
    private static let encryptedPrefix = Data("VC1".utf8)

    private let encryptor: DataEncryptor

    init(encryptor: DataEncryptor = AESGCMDataEncryptor()) {
        self.encryptor = encryptor
    }

    func loadData(contentsOf url: URL) throws -> Data {
        let raw = try Data(contentsOf: url)
        guard raw.starts(with: Self.encryptedPrefix) else {
            // Legacy plaintext written before encryption — returned as-is; next write re-encrypts.
            return raw
        }
        let ciphertext = raw.dropFirst(Self.encryptedPrefix.count)
        return try encryptor.decrypt(Data(ciphertext))
    }

    func writeData(_ data: Data, to url: URL, options: Data.WritingOptions = []) throws {
        let payload = try encryptor.encrypt(data)
        var wrapped = Self.encryptedPrefix
        wrapped.append(payload)
        try wrapped.write(to: url, options: options)
    }

    /// Re-encrypts legacy plaintext files on read when persisting again.
    func migrateLegacyFileIfNeeded(at url: URL) {
        guard let raw = try? Data(contentsOf: url), !raw.starts(with: Self.encryptedPrefix) else { return }
        try? writeData(raw, to: url, options: .atomic)
    }
}

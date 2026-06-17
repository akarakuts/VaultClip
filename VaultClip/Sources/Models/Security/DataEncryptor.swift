//
//  DataEncryptor.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Abstraction over symmetric encryption used to protect clipboard payloads on
/// disk. Production code uses `AESGCMDataEncryptor`; tests can inject a
/// pass-through implementation.
protocol DataEncryptor {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

enum DataEncryptionError: Error {
    case failedToSeal
}

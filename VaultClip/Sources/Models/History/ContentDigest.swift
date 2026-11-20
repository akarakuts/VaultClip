//
// ContentDigest — SHA-256 of sorted pasteboard type/payload pairs (T23).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import CryptoKit
import Foundation

enum ContentDigest {
    /// Hex SHA-256 over `(type.rawValue, bytes)` pairs sorted by type name.
    static func compute(from payload: [NSPasteboard.PasteboardType: Data]) -> String {
        var hasher = SHA256()
        for typeName in payload.keys.map(\.rawValue).sorted() {
            let type = NSPasteboard.PasteboardType(typeName)
            guard let bytes = payload[type] else { continue }
            hasher.update(data: Data(typeName.utf8))
            hasher.update(data: bytes)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

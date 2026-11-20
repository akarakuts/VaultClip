//
// QuickLookTempStore — short-lived 0600 PDF temps for QL; cleaned on close / clear / exit.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Writes decrypted PDF bytes to a private temp directory for Quick Look only.
final class QuickLookTempStore {
    static let shared = QuickLookTempStore()

    private let fileManager: FileManager
    private let directory: URL

    init(
        directory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("VaultClip-QL", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.fileManager = fileManager
    }

    func url(for id: UUID, data: Data) throws -> URL {
        try ensureDirectory()
        let url = directory.appendingPathComponent("\(id.uuidString).pdf")
        // Overwrite so a stale temp cannot outlive a content change.
        fileManager.createFile(atPath: url.path, contents: data, attributes: [.posixPermissions: 0o600])
        return url
    }

    func remove(id: UUID) {
        let url = directory.appendingPathComponent("\(id.uuidString).pdf")
        try? fileManager.removeItem(at: url)
    }

    func removeAll() {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try? fileManager.removeItem(at: directory)
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } else {
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        }
    }
}

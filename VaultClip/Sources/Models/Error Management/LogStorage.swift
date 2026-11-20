//
//  LogStorage.swift
//  VaultClip
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Log-file hygiene: restrictive permissions and size rotation for diagnostics logs.
enum LogStorage {

    static let logFilePermissions: Int16 = 0o600
    static let rotationThresholdBytes = 2_000_000
    static let rotatedTailBytes = 256_000

    /// Called once at launch: error/warning always rotate; pasteboard-debug only while diagnostics are on.
    static func secureAtLaunch() {
        // Resolve URLs at call time — StorageRoot.override may redirect Application Support.
        let errorLog = Constants.urls.errorLog
        let warningLog = Constants.urls.warningLog
        let debugLog = Constants.urls.pasteboardDebugLog
        secureAndPruneLogs(at: [errorLog, warningLog, debugLog]) { url in
            if url == debugLog {
                return PasteboardDiagnostics.isEnabled
            }
            return url == errorLog || url == warningLog
        }
    }

    /// Applies 0600 to existing log files and trims over-grown logs when `shouldRotate` allows.
    static func secureAndPruneLogs(
        at urls: [URL],
        shouldRotate: (URL) -> Bool = { _ in true },
        fileManager: FileManager = .default
    ) {
        for url in urls where fileManager.fileExists(atPath: url.path) {
            try? fileManager.setAttributes(
                [.posixPermissions: NSNumber(value: logFilePermissions)],
                ofItemAtPath: url.path
            )
            guard shouldRotate(url) else { continue }
            rotateIfNeeded(at: url, fileManager: fileManager)
        }
    }

    static func rotateIfNeeded(at url: URL, fileManager: FileManager = .default) {
        guard let size = (try? fileManager.attributesOfItem(atPath: url.path))?[.size] as? Int,
              size > rotationThresholdBytes else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        let tail = Data(data.suffix(rotatedTailBytes))
        fileManager.createFile(
            atPath: url.path,
            contents: tail,
            attributes: [.posixPermissions: NSNumber(value: logFilePermissions)]
        )
    }

    /// Creates a new empty log file with owner-only permissions when missing.
    static func ensureLogFileExists(at url: URL, fileManager: FileManager = .default) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        let parent = url.deletingLastPathComponent()
        try? fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        fileManager.createFile(
            atPath: url.path,
            contents: Data(),
            attributes: [.posixPermissions: NSNumber(value: logFilePermissions)]
        )
    }
}

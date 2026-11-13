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

    private static let knownLogURLs: [URL] = [
        Constants.urls.errorLog,
        Constants.urls.warningLog,
        Constants.urls.pasteboardDebugLog
    ]

    /// Called once at launch: logs never stay world-readable; diagnostics rotate only while enabled.
    static func secureAtLaunch() {
        secureAndPruneLogs(at: knownLogURLs) { url in
            url == Constants.urls.pasteboardDebugLog && PasteboardDiagnostics.isEnabled
        }
    }

    /// Applies 0600 to existing log files and trims over-grown diagnostics logs.
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
        let tail = data.suffix(rotatedTailBytes)
        try? Data(tail).write(to: url, options: .atomic)
    }
}

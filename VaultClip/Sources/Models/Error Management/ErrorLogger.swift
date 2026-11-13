//
//  ErrorLogger.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class ErrorLogger: Logger {
    
    static let general = ErrorLogger(url: Constants.urls.errorLog)
}

/// Opt-in pasteboard capture and history UI trace (`pasteboard-debug.log`).
/// Enabled only by launching with `--pasteboard-diagnostics`; off by default so plaintext
/// clipboard snippets never reach disk (history payloads are encrypted — diagnostics must not bypass that).
enum PasteboardDiagnostics {
    private static let logger = Logger(url: Constants.urls.pasteboardDebugLog)

    static var isEnabled = false

    static func log(_ message: String) {
        guard isEnabled else { return }
        LogStorage.rotateIfNeeded(at: Constants.urls.pasteboardDebugLog)
        logger.logLine(message)
    }
}



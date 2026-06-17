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

/// Pasteboard capture and history UI trace (`~/Library/Application Support/.../pasteboard-debug.log`).
enum PasteboardDiagnostics {
    private static let logger = Logger(url: Constants.urls.pasteboardDebugLog)

    static func log(_ message: String) {
        logger.logLine(message)
    }
}



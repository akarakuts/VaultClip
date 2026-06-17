//
//  WarningLogger.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class WarningLogger: Logger {
    
    static let general = WarningLogger(url: Constants.urls.warningLog)
}

//
//  ClipWarning.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct ClipWarning: Loggable {
    
    var localizedDescription: String
    
    var domain: String
    
    var consoleDescription: String {
        return "[\(domain)] \(localizedDescription)"
    }
    
    var logFileDescription: String {
        return "\(localizedDescription)"
    }
    
    init(domain: String = Constants.logging.historyWarningDomain, localizedDescription: String) {
        self.domain = domain
        self.localizedDescription = localizedDescription
    }
}

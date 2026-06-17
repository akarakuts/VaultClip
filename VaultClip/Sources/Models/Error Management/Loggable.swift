//
//  Loggable.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

protocol Loggable {
    
    var localizedDescription: String { get }
    
    var consoleDescription: String { get }
    
    var logFileDescription: String { get }
    
    var domain: String { get }
    
    func log(with logger: Logger)
}

extension Loggable {
    
    func log(with logger: Logger) {
        logger.log(self)
    }
}

//
//  ClipError.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

struct ClipError: Loggable, Alertable, Error {
    
    var error: Error
    
    var localizedDescription: String {
        return error.localizedDescription
    }
    
    var domain: String {
        return (error as NSError).domain
    }

    var code: ClipErrorCode {
        ClipErrorCode(rawValue: (error as NSError).code) ?? .unknown
    }
    
    var consoleDescription: String {
        return "[\(domain):\(code.rawValue)] \(localizedDescription)"
    }
    
    var logFileDescription: String {
        return "\(localizedDescription)"
    }
    
    init(error: Error) {
        self.error = error
    }
    
    init(domain: String = Constants.logging.historyErrorDomain, code: Int, userInfo: [String: Any]? = nil) {
        self.error = NSError(domain: domain, code: code, userInfo: userInfo)
    }

    init(_ code: ClipErrorCode, localizedDescription: String) {
        self.error = NSError(
            domain: Constants.logging.historyErrorDomain,
            code: code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
    
    init(domain: String = Constants.logging.historyErrorDomain, localizedDescription: String) {
        self.init(.unknown, localizedDescription: localizedDescription)
    }
    
    func createAlert() -> NSAlert {
        return NSAlert(error: error)
    }
    
    func logAndShow(withLogger logger: Logger, andAlerter alerter: Alerter = .general) {
        logger.log(self)
        alerter.show(self)
    }
}

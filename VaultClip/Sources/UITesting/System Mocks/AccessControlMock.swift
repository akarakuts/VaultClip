//
//  AccessControlMock.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

struct AccessControlMock {
    
    static let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "VaultClip.UITesting.AccessControl"))
    
    static func setControlGranted(_ access: Bool) {
        pasteboard.declareTypes([.string], owner: nil)
        let str = access ? "true" : "false"
        pasteboard.setString(str, forType: .string)
    }
    
    static func isControlGranted() -> Bool {
        return pasteboard.string(forType: .string) == "true"
    }
}

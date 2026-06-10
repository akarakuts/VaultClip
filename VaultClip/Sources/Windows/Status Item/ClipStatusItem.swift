//
//  ClipStatusItem.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class ClipStatusItem {
    
    static var statusItemButtonImage = NSImage(named: NSImage.Name("StatusBarIcon"))
    
    static func create() -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = statusItemButtonImage
            button.setAccessibilityIdentifier(Accessibility.identifiers.statusItemButton)
        }
        
        return statusItem
    }
}

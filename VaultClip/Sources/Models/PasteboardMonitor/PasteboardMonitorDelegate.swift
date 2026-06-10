//
//  PasteboardMonitorDelegate.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

protocol PasteboardMonitorDelegate {
    
    /**
     Called when the pasteboard changes.
     
     - Parameter pasteboard: The pasteboard that changed.
     */
    func pasteboardDidChange(_ pasteboard: NSPasteboard, originBundleId: String?)
}

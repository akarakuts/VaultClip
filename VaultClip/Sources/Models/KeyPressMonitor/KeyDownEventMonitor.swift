//
//  KeyDownEventMonitor.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class KeyDownEventMonitor: EventMonitor {
    
    init(handler: @escaping (NSEvent) -> Void) {
        super.init(eventTypeMask: .keyDown, handler: handler)
    }
}

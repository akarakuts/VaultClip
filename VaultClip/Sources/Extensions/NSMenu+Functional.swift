//
//  NSMenu+Functional.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

extension NSMenu {
    
    func with(menuItem: NSMenuItem) -> NSMenu {
        self.addItem(menuItem)
        return self
    }
}

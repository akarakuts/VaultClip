//
//  Alertable.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

protocol Alertable {
    
    func createAlert() -> NSAlert
    
    func show(with alerter: Alerter)
}

extension Alertable {
    
    func show(with alerter: Alerter) {
        alerter.show(self)
    }
}

//
//  NSView+ConstraintWithIdentifier.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSView {
    
    // https://stackoverflow.com/a/39111696
    
    func constraint(withIdentifier identifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter{ $0.identifier == identifier }.first
    }
    
    func removeConstraint(withIdentifier identifier: String) {
        if let constraint = constraints.filter({ $0.identifier == identifier }).first {
            removeConstraint(constraint)
        }
    }
    
    func addConstraint(_ constraint: NSLayoutConstraint, withIdentifier identifier: String) {
        constraint.identifier = identifier
        addConstraint(constraint)
    }
}


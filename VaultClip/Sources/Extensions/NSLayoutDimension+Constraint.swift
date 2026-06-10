//
//  NSLayoutDimension+Constraint.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSLayoutDimension {
    
    // https://stackoverflow.com/a/39111696
    
    @objc func constraint(equalToConstant constant: CGFloat, withIdentifier identifier: String) -> NSLayoutConstraint! {
        let constraint = self.constraint(equalToConstant: constant)
        constraint.identifier = identifier
        return constraint
    }
}

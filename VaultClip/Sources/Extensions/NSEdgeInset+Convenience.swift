//
//  NSEdgeInset+Convenience.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSEdgeInsets {
    
    var yTotal: CGFloat {
        return top + bottom
    }
    
    var xTotal: CGFloat {
        return left + right
    }
}

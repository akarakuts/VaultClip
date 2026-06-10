//
//  Array+Functional.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension Array {
    
    func with(elementAppened element: Element) -> Array {
        var copy = self
        copy.append(element)
        return copy
    }
    
    func with(element: Element, insertedAt i: Int) -> Array {
        var copy = self
        copy.insert(element, at: i)
        return copy
    }
    
    func without(elementAt i: Int) -> Array {
        var copy = self
        copy.remove(at: i)
        return copy
    }
}

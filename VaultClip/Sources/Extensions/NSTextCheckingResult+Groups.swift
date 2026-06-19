//
//  NSTextCheckingResult+Groups.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSTextCheckingResult {
    
    /// https://stackoverflow.com/a/51384977
    func groups(testedString: String) -> [String] {
        var groups = [String]()
        for i in 0 ..< numberOfRanges {
            guard let range = Range(self.range(at: i), in: testedString) else { continue }
            let group = String(testedString[range])
            groups.append(group)
        }
        return groups
    }
}

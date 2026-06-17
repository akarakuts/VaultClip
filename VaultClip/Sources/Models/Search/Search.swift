//
//  Search.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

// Adapted from: https://github.com/khoi/fuzzy-swift/blob/master/Sources/Fuzzy/Fuzzy.swift
public func performSearch(needle: String, haystack: String) -> Bool {
    guard needle.count <= haystack.count else {
        return false
    }

    if needle == haystack {
        return true
    }

    var needleIdx = needle.startIndex
    var haystackIdx = haystack.startIndex

    while needleIdx != needle.endIndex {
        if haystackIdx == haystack.endIndex {
            return false
        }
        if String(needle[needleIdx]).localizedCaseInsensitiveCompare(String(haystack[haystackIdx])) == .orderedSame {
            needleIdx = needle.index(after: needleIdx)
        }
        haystackIdx = haystack.index(after: haystackIdx)
    }

    return true
}

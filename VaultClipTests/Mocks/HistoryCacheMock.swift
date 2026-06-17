//
//  HistoryCacheMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class HistoryCacheMock: HistoryCache {
    
    var data: Data?
    
    var dataCallCount = 0
    
    override func data(withId id: UUID, forType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCount += 1
        return data
    }
}

//
//  ArrayFileManagerMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class ArrayFileManagerMock: ArrayFileManager {
    
    var order: NSArray?
    var shouldReadSucceed = true
    var shouldWriteSucceed = true
    private(set) var writeCount = 0

    override func read() -> NSArray? {
        if shouldReadSucceed {
            return order
        }
        else {
            return nil
        }
    }

    override func write(_ array: NSArray, options: Data.WritingOptions) throws {
        writeCount += 1
        if shouldWriteSucceed {
            order = array
        }
        else {
            throw NSError(domain: "Testing skrt", code: 0, userInfo: [:])
        }
    }
}

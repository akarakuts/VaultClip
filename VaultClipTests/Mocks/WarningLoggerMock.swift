//
//  WarningLoggerMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class WarningLoggerMock: WarningLogger {
    
    var expectation: XCTestExpectation!
    
    init() {
        super.init(url: URL(fileURLWithPath: "test"))
    }
    
    override func log(_ loggable: Loggable) {
        expectation.fulfill()
    }
}

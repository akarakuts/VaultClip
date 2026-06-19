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
    
    var expectation: XCTestExpectation?
    private(set) var loggedWarnings = 0
    
    init() {
        super.init(url: URL(fileURLWithPath: "test"))
    }
    
    override func log(_ loggable: Loggable) {
        loggedWarnings += 1
        guard let expectation else { return }
        expectation.fulfill()
        if expectation.expectedFulfillmentCount == 1 {
            self.expectation = nil
        }
    }
}

//
//  ErrorLoggerMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class ErrorLoggerMock: ErrorLogger {
    
    var expectation: XCTestExpectation?
    private(set) var loggedErrors = 0
    
    init() {
        super.init(url: URL(fileURLWithPath: "test"))
    }
    
    override func log(_ loggable: Loggable) {
        loggedErrors += 1
        guard let expectation else { return }
        expectation.fulfill()
        if expectation.expectedFulfillmentCount == 1 {
            self.expectation = nil
        }
    }
}

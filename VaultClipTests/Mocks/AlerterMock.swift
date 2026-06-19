//
//  AlerterMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class AlerterMock: Alerter {
    
    var expectation: XCTestExpectation?
    private(set) var shownAlerts = 0
    
    override func show(_ alertable: Alertable) {
        shownAlerts += 1
        guard let expectation else { return }
        expectation.fulfill()
        if expectation.expectedFulfillmentCount == 1 {
            self.expectation = nil
        }
    }
}

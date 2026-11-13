//
//  PasteboardMonitorTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class PasteboardMonitorTests: XCTestCase {

    func testPasteboardDidChangeCalled() {
        // 1. Given
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "test"))
        let delegate = PasteboardMonitorDelegateMock(expectation: self.expectation(description: "pasteboardDidChangeCalled"))
        let monitor = PasteboardMonitor(pasteboard: pasteboard, changeCount: pasteboard.changeCount, delegate: delegate)

        // 2. Add something to the pasteboard, then hand the gate a change count that is
        // still behind the live one — the backlog must be delivered synchronously.
        pasteboard.setString("test", forType: .string)
        monitor.historyReady(liveChangeCount: pasteboard.changeCount - 1)

        // 3. Assert delegate function called
        XCTAssertEqual(pasteboard.string(forType: .string), "test")
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testChangeCountDetectedOnlyAfterHistoryReady() {
        // Changes noticed while the load gate is closed must not reach the delegate;
        // the launch sync owns that backlog (P6.3).
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "test2"))
        let quiet = XCTestExpectation(description: "delegate stays quiet")
        quiet.isInverted = true
        let delegate = PasteboardMonitorDelegateMock(expectation: quiet)
        _ = PasteboardMonitor(pasteboard: pasteboard, changeCount: pasteboard.changeCount, delegate: delegate)

        pasteboard.setString("gated", forType: .string)

        wait(for: [quiet], timeout: 0.6)
        XCTAssertTrue(delegate.received.isEmpty)
    }

    func testPerformancePasteboardChangeDetection() {
        self.measure {
            testPasteboardDidChangeCalled()
        }
    }
}

class PasteboardMonitorDelegateMock: PasteboardMonitorDelegate {

    var expectation: XCTestExpectation
    private(set) var received: [String?] = []

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func pasteboardDidChange(_ pasteboard: NSPasteboard, originBundleId: String?) {
        received.append(originBundleId)
        expectation.fulfill()
    }
}

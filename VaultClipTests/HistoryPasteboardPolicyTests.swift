//
//  HistoryPasteboardPolicyTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryPasteboardPolicyTests: XCTestCase {

    func testDenylistBlocksOnePassword() {
        XCTAssertTrue(HistoryPasteboardPolicy.shouldIgnoreSource(bundleId: "com.1password.1password"))
    }

    func testDenylistAllowsNormalApps() {
        XCTAssertFalse(HistoryPasteboardPolicy.shouldIgnoreSource(bundleId: "com.apple.Safari"))
        XCTAssertFalse(HistoryPasteboardPolicy.shouldIgnoreSource(bundleId: nil))
    }

    func testConcealedTypesAreDropped() {
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        let plain = NSPasteboard.PasteboardType.string
        let result = HistoryPasteboardPolicy.usableTypes(from: [concealed, plain])
        XCTAssertTrue(result.isEmpty)
    }

    func testPlainTextSurvivesFiltering() {
        let plain = NSPasteboard.PasteboardType.string
        let result = HistoryPasteboardPolicy.usableTypes(from: [plain])
        XCTAssertEqual(result, [plain])
    }
}

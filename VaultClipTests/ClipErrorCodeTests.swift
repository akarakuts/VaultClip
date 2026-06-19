//
//  ClipErrorCodeTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ClipErrorCodeTests: XCTestCase {

    func testStableHistoryErrorCodes() {
        XCTAssertEqual(ClipErrorCode.historyOrderWriteFailed.rawValue, 1001)
        XCTAssertEqual(ClipErrorCode.historyItemDeleteFailed.rawValue, 1007)
    }

    func testClipErrorExposesCode() {
        let error = ClipError(.historyOrderDecryptFailed, localizedDescription: "decrypt failed")
        XCTAssertEqual(error.code, .historyOrderDecryptFailed)
        XCTAssertTrue(error.consoleDescription.contains("1002"))
    }

    func testUnknownCodeMapsToEnum() {
        let error = ClipError(code: 999_999, userInfo: [NSLocalizedDescriptionKey: "x"])
        XCTAssertEqual(error.code, .unknown)
    }
}

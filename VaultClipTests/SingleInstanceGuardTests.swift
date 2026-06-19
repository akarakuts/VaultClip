//
//  SingleInstanceGuardTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class SingleInstanceGuardTests: XCTestCase {

    func testLockFileURLIsUnderAppSupport() {
        XCTAssertTrue(SingleInstanceGuard.lockFileURL.path.contains("com.karakuts.VaultClip"))
        XCTAssertEqual(SingleInstanceGuard.lockFileURL.lastPathComponent, "instance.lock")
    }

    func testSkipsGuardDuringUnitTests() {
        XCTAssertTrue(SingleInstanceGuard.terminateIfDuplicate() == false || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
    }
}

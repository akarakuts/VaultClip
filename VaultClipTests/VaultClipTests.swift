//
//  VaultClipTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class VaultClipTests: XCTestCase {

    func testBrandingConstants() {
        XCTAssertEqual(Constants.branding.bundleIdentifier, "com.karakuts.VaultClip")
    }
}

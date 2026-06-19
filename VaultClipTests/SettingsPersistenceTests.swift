//
//  SettingsPersistenceTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class SettingsPersistenceTests: XCTestCase {

    private var productionEnvironment: AppEnvironment!
    private var savedDefaults: [String: Any]!

    override func setUp() {
        super.setUp()
        productionEnvironment = AppEnvironment.shared
        savedDefaults = UserDefaults.standard.blank()
        Settings.bootstrapOverride = nil
    }

    override func tearDown() {
        UserDefaults.standard.restore(from: savedDefaults)
        VaultClipTestSupport.reinstallSharedPointers(from: productionEnvironment)
        productionEnvironment = nil
        super.tearDown()
    }

    func testApplyWithoutEnvironmentUsesBootstrapOverride() {
        AppEnvironment.shared = nil
        Settings.installShared(.default)
        SettingsPersistence.apply { $0.maxHistory = 77 }
        XCTAssertEqual(SettingsPersistence.current().maxHistory, 77)
    }

    func testApplyWithEnvironmentUpdatesSharedSettings() {
        let env = AppEnvironment.bootstrap(settings: .default)
        SettingsPersistence.apply { $0.panelPosition = .bottom }
        XCTAssertEqual(env.settings.panelPosition, .bottom)
        XCTAssertEqual(SettingsPersistence.current().panelPosition, .bottom)
    }
}

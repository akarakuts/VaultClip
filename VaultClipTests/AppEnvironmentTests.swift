//
//  AppEnvironmentTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class AppEnvironmentTests: XCTestCase {

    private var productionEnvironment: AppEnvironment!

    override func setUp() {
        super.setUp()
        productionEnvironment = AppEnvironment.shared
    }

    override func tearDown() {
        VaultClipTestSupport.reinstallSharedPointers(from: productionEnvironment)
        productionEnvironment = nil
        super.tearDown()
    }

    func testBootstrapWiresStateAndSettings() {
        let settings = Settings.default
        let env = AppEnvironment.bootstrap(settings: settings)
        XCTAssertTrue(env.state === State.main)
        XCTAssertEqual(env.settings.maxHistory, settings.maxHistory)
    }

    func testUpdateSettingsPersistsToMain() {
        let env = AppEnvironment.bootstrap(settings: .default)
        env.updateSettings { $0.maxHistory = 123 }
        XCTAssertEqual(Settings.main.maxHistory, 123)
    }

    func testAttachControllerInstallsMain() {
        let env = AppEnvironment.bootstrap(settings: .default)
        let controller = Controller(state: env.state, settings: env.settings)
        env.attachController(controller)
        XCTAssertTrue(Controller.main === controller)
        XCTAssertTrue(env.routing === controller)
    }
}

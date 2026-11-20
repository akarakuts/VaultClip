//
// StorageRootTests — isolation of Application Support under test host / override.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class StorageRootTests: XCTestCase {

    private var previousOverride: URL?

    override func setUp() {
        super.setUp()
        previousOverride = StorageRoot.override
    }

    override func tearDown() {
        StorageRoot.override = previousOverride
        super.tearDown()
    }

    func testOverrideRedirectsHistoryUnderOverrideRoot() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultClip-StorageRootTests-\(UUID().uuidString)", isDirectory: true)
        StorageRoot.override = root

        XCTAssertEqual(Constants.urls.applicationSupport, root)
        XCTAssertTrue(Constants.urls.history.path.hasPrefix(root.path))
        XCTAssertEqual(
            Constants.urls.appSupport.lastPathComponent,
            AppIdentity.bundleIdentifier
        )
    }

    func testUnitTestHostDoesNotUseProductionAppSupport() {
        XCTAssertTrue(AppIdentity.isRunningUnitTests)
        let isolated = Constants.urls.appSupport.resolvingSymlinksInPath().standardizedFileURL
        let production = AppIdentity.productionAppSupportURL.resolvingSymlinksInPath().standardizedFileURL
        XCTAssertNotEqual(isolated, production)
        XCTAssertFalse(isolated.path.hasPrefix(production.path + "/"))
    }
}

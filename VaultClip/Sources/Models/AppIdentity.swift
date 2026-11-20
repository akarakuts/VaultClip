//
// AppIdentity — process identity and storage root overrides for production vs tests.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Resolves the running bundle id and whether this process may touch production data.
enum AppIdentity {

    static let productionBundleIdentifier = Constants.branding.bundleIdentifier

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? productionBundleIdentifier
    }

    static var isProduction: Bool {
        bundleIdentifier == productionBundleIdentifier
    }

    /// True when this process is the XCTest host (unit or UI test runner).
    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Canonical production Application Support folder (never redirected by StorageRoot).
    static var productionAppSupportURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
        return support.appendingPathComponent(productionBundleIdentifier, isDirectory: true)
    }

    /// Fails in DEBUG if a test mode still points at the user's real history folder.
    static func assertStorageIsIsolatedIfNeeded() {
        #if DEBUG
        guard isRunningUnitTests || UITesting.isRunning else { return }
        let isolated = Constants.urls.appSupport.resolvingSymlinksInPath().standardizedFileURL
        let production = productionAppSupportURL.resolvingSymlinksInPath().standardizedFileURL
        precondition(
            isolated != production,
            "Test mode must not use production Application Support at \(production.path)"
        )
        #endif
    }
}

/// Optional override of the Application Support root (DEBUG / tests only).
enum StorageRoot {

    #if DEBUG
    static var override: URL?
    #else
    static var override: URL? { nil }
    #endif
}

//
//  UITesting.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct UITesting {

    #if DEBUG
    /// True when the app was launched for UI testing (`--uitesting`).
    static let isRunning = CommandLine.arguments.contains("--uitesting")

    static func setupUITestEnvironment(launchArgs: [String], environment: [String: String]) throws {
        Helper.accessControlHelper = AccessControlHelperMock()
        Helper.keyPressHelper = KeyPressHelperMock()

        _ = UserDefaults.standard.blank()

        if let test = CommandLine.arguments.first(where: { $0.contains("--Settings.testData=") }),
           let settings = Settings.testData.from(test) {
            Settings.main = settings
        }

        try loadTestAppSupport(launchArgs: launchArgs, environment: environment)
        AppIdentity.assertStorageIsIsolatedIfNeeded()
    }

    /// Copies fixture data into a temporary Application Support root — never the production folder.
    static func loadTestAppSupport(launchArgs: [String], environment: [String: String]) throws {
        guard let testData = launchArgs.first(where: { $0.contains("--test-dir=") }) else {
            return
        }
        let pattern = "--test-dir=(.*)"
        let regex = try NSRegularExpression(pattern: pattern)
        guard let firstMatch = regex.firstMatch(in: testData, range: NSRange(location: 0, length: testData.count)) else {
            return
        }
        let groups = firstMatch.groups(testedString: testData)
        if groups.count < 2 {
            return
        }
        let test = groups[1]

        guard let srcroot = environment["SRCROOT"] else {
            throw NSError(domain: "UITestError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Cannot load test app support directory because the SRCROOT environment variable is not set."
            ])
        }
        guard let testDir = NSURL(fileURLWithPath: srcroot)
            .appendingPathComponent("TestData", isDirectory: true)?
            .appendingPathComponent(test, isDirectory: true) else {
            throw NSError(domain: "UITestError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create test url for path srcroot/TestData/\(test)."
            ])
        }
        guard FileManager.default.fileExists(atPath: testDir.path) else {
            throw NSError(domain: "TestDirectoryError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Could not copy test directory \(test) because it doesn't exist."
            ])
        }

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultClip-UITests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        StorageRoot.override = root

        let destination = Constants.urls.appSupport
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: testDir, to: destination)
    }
    #else
    static let isRunning = false
    #endif
}

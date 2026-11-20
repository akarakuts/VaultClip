//
// SettingsDecodeTests — resilient Settings JSON decode (T17).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class SettingsDecodeTests: XCTestCase {

    func testMissingPastesRichTextKeepsOtherFields() throws {
        var base = Settings.default
        base.panelPosition = .left
        base.pasteboardChangeCount = 42
        base.maxHistory = 50
        base.showsRichText = false
        base.pastesRichText = false
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as! [String: Any]
        object.removeValue(forKey: "pastesRichText")
        let json = try JSONSerialization.data(withJSONObject: object)

        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.panelPosition, .left)
        XCTAssertEqual(settings.pasteboardChangeCount, 42)
        XCTAssertEqual(settings.maxHistory, 50)
        XCTAssertFalse(settings.showsRichText)
        XCTAssertEqual(settings.pastesRichText, Settings.default.pastesRichText)
    }

    func testCorruptJSONBacksUpAndReturnsDefault() {
        let defaults = UserDefaults.standard
        let previous = defaults.data(forKey: "settings")
        let previousBackup = defaults.data(forKey: Settings.corruptBackupKey)
        defer {
            defaults.set(previous, forKey: "settings")
            defaults.set(previousBackup, forKey: Settings.corruptBackupKey)
        }

        let garbage = Data("not-json".utf8)
        defaults.set(garbage, forKey: "settings")
        let loaded = Settings.loadPersisted()
        XCTAssertEqual(loaded.panelPosition, Settings.default.panelPosition)
        XCTAssertEqual(defaults.data(forKey: Settings.corruptBackupKey), garbage)
    }
}

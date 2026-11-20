//
// L10nCatalogTests — every L10n key exists and is translated for en/ru (T35).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class L10nCatalogTests: XCTestCase {
    func testAllL10nKeysTranslatedForEnAndRu() throws {
        let root = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = root.appendingPathComponent("VaultClip/Resources/Localizable.xcstrings")
        let l10nURL = root.appendingPathComponent("VaultClip/Sources/Localization/L10n.swift")
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalogURL.path), catalogURL.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: l10nURL.path), l10nURL.path)

        let data = try Data(contentsOf: catalogURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = try XCTUnwrap(json?["strings"] as? [String: Any])
        let l10nSource = try String(contentsOf: l10nURL)
        let pattern = try NSRegularExpression(pattern: #"tr\(\s*"([^"]+)""#)
        let matches = pattern.matches(in: l10nSource, range: NSRange(l10nSource.startIndex..., in: l10nSource))
        var keys = Set<String>()
        for match in matches {
            if let range = Range(match.range(at: 1), in: l10nSource) {
                keys.insert(String(l10nSource[range]))
            }
        }
        XCTAssertFalse(keys.isEmpty)

        for key in keys.sorted() {
            let entry = try XCTUnwrap(strings[key] as? [String: Any], "missing key \(key)")
            let locs = try XCTUnwrap(entry["localizations"] as? [String: Any])
            for lang in ["en", "ru"] {
                let loc = try XCTUnwrap(locs[lang] as? [String: Any], "\(key) missing \(lang)")
                let unit = try XCTUnwrap(loc["stringUnit"] as? [String: Any])
                XCTAssertEqual(unit["state"] as? String, "translated", "\(key) \(lang)")
                XCTAssertFalse((unit["value"] as? String ?? "").isEmpty, "\(key) \(lang) empty")
            }
        }
    }
}

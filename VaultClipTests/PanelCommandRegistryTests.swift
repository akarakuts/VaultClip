//
// PanelCommandRegistryTests — chord uniqueness, titles, layout-aware ⌘K/⌘1 (U03).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelCommandRegistryTests: XCTestCase {

    func testNoDuplicateChordsWithinZone() {
        var seen: [FocusZone: [KeyChord: PanelCommandID]] = [:]
        for cmd in PanelCommandRegistry.all {
            for binding in cmd.bindings {
                for zone in binding.zones {
                    var map = seen[zone, default: [:]]
                    if let existing = map[binding.chord] {
                        XCTFail("\(binding.chord) in \(zone) claimed by \(existing) and \(cmd.id)")
                    }
                    map[binding.chord] = cmd.id
                    seen[zone] = map
                }
            }
        }
    }

    func testEveryCommandHasSymbolAndPaletteOrMenuOnly() {
        for cmd in PanelCommandRegistry.all {
            XCTAssertFalse(cmd.symbolName.isEmpty, "\(cmd.id) missing symbol")
            XCTAssertFalse(cmd.titleKey.isEmpty, "\(cmd.id) missing title key")
            // Either shown in palette or explicitly menu-bar only.
            _ = cmd.showsInPalette
        }
        XCTAssertFalse(PanelCommandRegistry.command(id: .togglePanel).showsInPalette)
        XCTAssertTrue(PanelCommandRegistry.command(id: .commandPalette).showsInPalette)
    }

    func testCommandTitlesExistInCatalogForEnAndRu() throws {
        let root = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = root.appendingPathComponent("VaultClip/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = try XCTUnwrap(json?["strings"] as? [String: Any])

        for cmd in PanelCommandRegistry.all {
            let entry = try XCTUnwrap(strings[cmd.titleKey] as? [String: Any], cmd.titleKey)
            let locs = try XCTUnwrap(entry["localizations"] as? [String: Any])
            for lang in ["en", "ru"] {
                let loc = try XCTUnwrap(locs[lang] as? [String: Any], "\(cmd.titleKey) \(lang)")
                let unit = try XCTUnwrap(loc["stringUnit"] as? [String: Any])
                XCTAssertEqual(unit["state"] as? String, "translated")
                XCTAssertFalse((unit["value"] as? String ?? "").isEmpty)
            }
        }
    }

    func testCommandKRecognizedOnUSRussianAndDvorak() {
        let chord = KeyChord.cmd("k")
        let cases: [(KeyboardLayoutTranslating, UInt16)] = [
            (MapLayoutTranslator.us, 40),            // US k
            (MapLayoutTranslator.russianPhysical, 40), // physical л / ASCII k
            (MapLayoutTranslator.dvorak, 9)           // Dvorak k on ANSI V
        ]
        for (translator, keyCode) in cases {
            let matcher = KeyChordMatcher(translator: translator)
            XCTAssertTrue(
                matcher.matches(chord, keyCode: keyCode, modifiers: .command),
                "⌘K failed for keyCode \(keyCode)"
            )
        }
    }

    func testCommand1RecognizedOnUSRussianAndDvorak() {
        let chord = KeyChord.cmdDigit(1)
        for translator in [MapLayoutTranslator.us, .russianPhysical, .dvorak] as [MapLayoutTranslator] {
            let matcher = KeyChordMatcher(translator: translator)
            XCTAssertTrue(matcher.matches(chord, keyCode: 18, modifiers: .command))
        }
    }

    func testControlSpaceIsNotBound() {
        let spaceCtrl = KeyChord(key: .space, modifiers: .control)
        for zone in FocusZone.allCases {
            XCTAssertTrue(
                PanelCommandRegistry.commands(matching: spaceCtrl, in: zone).isEmpty,
                "⌃Space bound in \(zone)"
            )
        }
    }

    func testRegistryCoversAllCommandIDs() {
        let registered = Set(PanelCommandRegistry.all.map(\.id))
        for id in PanelCommandID.allCases {
            XCTAssertTrue(registered.contains(id), "missing \(id)")
        }
    }
}

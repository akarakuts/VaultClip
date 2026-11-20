//
// HistoryQuarantineTests — undecryptable items move to quarantine instead of deletion.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryQuarantineTests: XCTestCase {

    private var previousOverride: URL?
    private var root: URL!

    override func setUpWithError() throws {
        previousOverride = StorageRoot.override
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("HistoryQuarantineTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        StorageRoot.override = root
        try FileManager.default.createDirectory(at: Constants.urls.history, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        StorageRoot.override = previousOverride
        try? FileManager.default.removeItem(at: root)
    }

    func testProbeReadabilityMarksGarbageCiphertextUndecryptable() throws {
        let id = UUID()
        let itemDir = Constants.urls.history.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: itemDir, withIntermediateDirectories: true)
        var payload = Data("VC1".utf8)
        payload.append(Data(repeating: 0xAB, count: 48))
        try payload.write(to: itemDir.appendingPathComponent("public.utf8-plain-text"))

        let manager = HistoryFileManager()
        XCTAssertEqual(
            manager.probeReadability(itemDirectory: itemDir, types: [.string]),
            .undecryptable
        )
    }

    func testMakeHistoryQuarantinesUndecryptableItem() throws {
        let id = UUID()
        let itemDir = Constants.urls.history.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: itemDir, withIntermediateDirectories: true)
        var payload = Data("VC1".utf8)
        payload.append(Data(repeating: 0xCD, count: 48))
        try payload.write(to: itemDir.appendingPathComponent("public.utf8-plain-text"))

        let orderPlist = try PropertyListSerialization.data(
            fromPropertyList: [id.uuidString],
            format: .xml,
            options: 0
        )
        try DataFileManager().writeData(orderPlist, to: Constants.urls.historyOrder)

        let cache = HistoryCache()
        let history = HistoryFileManager().loadHistory(cache: cache)

        XCTAssertFalse(history.items.contains(where: { $0.fsId == id }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: itemDir.path))

        let quarantine = Constants.urls.quarantine
        let enumerator = FileManager.default.enumerator(at: quarantine, includingPropertiesForKeys: nil)
        var found = false
        while let url = enumerator?.nextObject() as? URL {
            if url.lastPathComponent == id.uuidString {
                found = true
                break
            }
        }
        XCTAssertTrue(found, "quarantined item directory should exist under \(quarantine.path)")
    }
}

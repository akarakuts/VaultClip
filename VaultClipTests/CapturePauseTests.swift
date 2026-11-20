//
// CapturePauseTests — paused capture records changeCount only (T31).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class CapturePauseTests: XCTestCase {
    private var previous: Bool!

    override func setUp() {
        super.setUp()
        previous = Settings.main.isCapturePaused
    }

    override func tearDown() {
        SettingsPersistence.apply { $0.isCapturePaused = previous }
        super.tearDown()
    }

    func testPausedCaptureDoesNotInsert() {
        SettingsPersistence.apply { $0.isCapturePaused = true }
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.pause"))
        pb.clearContents()
        pb.setString("paused", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        XCTAssertTrue(history.items.isEmpty)
        XCTAssertEqual(history.lastRecordedChangeCount, pb.changeCount)
    }

    func testResumeAllowsInsert() {
        SettingsPersistence.apply { $0.isCapturePaused = false }
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.resume"))
        pb.clearContents()
        pb.setString("live", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        XCTAssertEqual(history.items.count, 1)
    }
}

//
// PlainTextPasteTests — Shift+Return writes only .string (T32).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PlainTextPasteTests: XCTestCase {
    func testPlainTextPasteFromRTFWritesOnlyString() throws {
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let rich = NSAttributedString(string: "Hello RTF", attributes: [.font: NSFont.boldSystemFont(ofSize: 14)])
        let rtf = try rich.data(from: NSRange(location: 0, length: rich.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let item = HistoryItem(unsavedData: [.rtf: rtf], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 10)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.plainPaste"))
        pb.clearContents()
        SettingsPersistence.apply { $0.requiresPasswordAuthentication = false }
        let panel = HistoryPanel(history: history, items: [item], pasteboard: pb)
        panel.paste(item: item, plainTextOnly: true)
        XCTAssertEqual(pb.string(forType: .string), "Hello RTF")
        XCTAssertNil(pb.data(forType: .rtf))
    }
}

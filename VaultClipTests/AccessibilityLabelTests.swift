//
// AccessibilityLabelTests — VoiceOver labels never leak password secrets (T36).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class AccessibilityLabelTests: XCTestCase {
    func testPasswordLabelMasksSecret() {
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let secret = "top-secret-password"
        let item = HistoryItem(
            unsavedData: [.string: Data(secret.utf8)],
            cache: cache,
            isPassword: true,
            passwordComment: "Bank"
        )
        let label = HistoryItemText.accessibilityLabel(for: item, listMode: .passwords)
        XCTAssertFalse(label.contains(secret))
        XCTAssertTrue(label.contains(HistoryItemText.passwordMask) || label.contains(L10n.a11yTypePassword))
    }

    func testTextLabelIncludesPreviewPrefix() {
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let item = HistoryItem(unsavedData: [.string: Data("Hello accessibility world".utf8)], cache: cache)
        let label = HistoryItemText.accessibilityLabel(for: item, listMode: .history)
        XCTAssertTrue(label.contains("Hello"))
    }
}

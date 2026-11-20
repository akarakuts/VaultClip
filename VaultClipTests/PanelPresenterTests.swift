//
// PanelPresenterTests — kind fixtures, formatting, password mask, perf (U05).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelPresenterTests: XCTestCase {

    func testClassifierPriorityAndKinds() {
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: true, typeIdentifiers: ["public.png"], plainText: nil, fileURLCount: 0)),
            .password
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["com.apple.cocoa.pasteboard.color"], plainText: nil, fileURLCount: 0)),
            .color
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.png"], plainText: nil, fileURLCount: 0)),
            .image
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["com.adobe.pdf"], plainText: nil, fileURLCount: 0)),
            .pdf
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.file-url"], plainText: nil, fileURLCount: 3)),
            .file(3)
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.url"], plainText: nil, fileURLCount: 0)),
            .link
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.utf8-plain-text"], plainText: "https://example.com/a", fileURLCount: 0)),
            .link
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.rtf"], plainText: "hi", fileURLCount: 0)),
            .richText
        )
        XCTAssertEqual(
            ItemKindClassifier.classify(.init(isPassword: false, typeIdentifiers: ["public.utf8-plain-text"], plainText: "hello", fileURLCount: 0)),
            .text
        )
    }

    func testPasswordNeverShowsSecret() {
        let summary = ItemSummary(
            title: "s3cret-password-value",
            charCount: 20,
            lineCount: 1,
            linkHost: nil,
            fileNames: [],
            imagePixelSize: nil,
            imageFormat: nil,
            colorHex: nil,
            sourceBundleId: "com.apple.Safari",
            copiedAt: Date(),
            lastUsedAt: Date(),
            kind: .password,
            passwordComment: "",
            pdfPageCount: nil,
            isRichText: false
        )
        let title = RowPresentationBuilder.title(for: summary, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(title, "Password")
        XCTAssertFalse(title.contains("s3cret"))
        let ru = RowPresentationBuilder.title(for: summary, locale: Locale(identifier: "ru_RU"))
        XCTAssertEqual(ru, "Пароль")
    }

    func testFormattingEnAndRuPlurals() {
        let files = ItemSummary(
            title: "",
            charCount: 0,
            lineCount: 0,
            linkHost: nil,
            fileNames: ["a.txt", "b.txt", "c.txt"],
            imagePixelSize: nil,
            imageFormat: nil,
            colorHex: nil,
            sourceBundleId: nil,
            copiedAt: Date(),
            lastUsedAt: Date(),
            kind: .file(3),
            passwordComment: nil,
            pdfPageCount: nil,
            isRichText: false
        )
        let en = RowPresentationBuilder.title(for: files, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(en.contains("and 2 more"), en)
        let ru = RowPresentationBuilder.title(for: files, locale: Locale(identifier: "ru_RU"))
        XCTAssertTrue(ru.contains("и ещё 2"), ru)
    }

    func testShortcutNumbersSkipHeaders() {
        let now = Date()
        let ids = (0..<3).map { _ in UUID() }
        let items = ids.map { _ in
            ItemSummary(
                title: "line",
                charCount: 4,
                lineCount: 1,
                linkHost: nil,
                fileNames: [],
                imagePixelSize: nil,
                imageFormat: nil,
                colorHex: nil,
                sourceBundleId: nil,
                copiedAt: now,
                lastUsedAt: now,
                kind: .text,
                passwordComment: nil,
                pdfPageCount: nil,
                isRichText: false
            )
        }
        // Force two day groups by shifting one item.
        var shifted = items
        shifted[2].lastUsedAt = now.addingTimeInterval(-86_400 * 3)
        let output = PanelPresenter.present(PanelPresenterInput(
            items: shifted,
            itemIds: ids,
            tab: .history,
            searchQuery: "",
            selectedIds: [],
            groupByDay: true,
            now: now,
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US")
        ))
        let shortcuts = output.rows.compactMap { row -> Int? in
            if case .item(_, let n) = row { return n }
            return nil
        }
        XCTAssertEqual(shortcuts, [1, 2, 3])
        XCTAssertTrue(output.rows.contains { if case .header = $0 { return true }; return false })
    }

    func testPresenterPerformance5000Items() {
        let now = Date()
        let count = 5_000
        let ids = (0..<count).map { _ in UUID() }
        let items: [ItemSummary] = (0..<count).map { i in
            ItemSummary(
                title: "Item \(i)\nsecond",
                charCount: 20,
                lineCount: 2,
                linkHost: nil,
                fileNames: [],
                imagePixelSize: nil,
                imageFormat: nil,
                colorHex: nil,
                sourceBundleId: "com.example.app",
                copiedAt: now.addingTimeInterval(TimeInterval(-i)),
                lastUsedAt: now.addingTimeInterval(TimeInterval(-i * 60)),
                kind: .text,
                passwordComment: nil,
                pdfPageCount: nil,
                isRichText: false
            )
        }
        let input = PanelPresenterInput(
            items: items,
            itemIds: ids,
            tab: .history,
            searchQuery: "",
            selectedIds: [ids[10], ids[20]],
            groupByDay: true,
            now: now,
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US")
        )
        measure {
            let output = PanelPresenter.present(input)
            XCTAssertEqual(output.visibleCount, count)
        }
        let start = CFAbsoluteTimeGetCurrent()
        _ = PanelPresenter.present(input)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        XCTAssertLessThan(elapsed, 200, "presenter took \(elapsed) ms")
    }
}

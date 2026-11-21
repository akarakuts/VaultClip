//
// RowPresentationFormattingTests — compact age, plurals, app names, color/image facts (U05/U11).
//
import AppKit
import XCTest
@testable import VaultClip

final class RowPresentationFormattingTests: XCTestCase {
    private let locale = Locale.current
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testRelativeTimeNeverSigned() {
        let cases: [(TimeInterval, String)] = [
            (10, L10n.relativeJustNow),
            (5 * 60, L10n.relativeMinutes(5)),
            (2 * 3600, L10n.relativeHours(2)),
            (3 * 86_400, L10n.relativeDays(3))
        ]
        for (ago, expected) in cases {
            let date = now.addingTimeInterval(-ago)
            XCTAssertEqual(RowPresentationBuilder.relativeTime(from: date, to: now, locale: locale), expected)
        }
        let future = now.addingTimeInterval(120)
        XCTAssertEqual(RowPresentationBuilder.relativeTime(from: future, to: now, locale: locale), L10n.relativeJustNow)
        let old = RowPresentationBuilder.relativeTime(from: now.addingTimeInterval(-30 * 86_400), to: now, locale: locale)
        XCTAssertFalse(old.contains("-"))
    }

    func testRussianPlural() {
        let forms = (1...25).map { RowPresentationBuilder.russianPlural($0, one: "файл", few: "файла", many: "файлов") }
        XCTAssertEqual(forms[0], "файл")
        XCTAssertEqual(forms[1], "файла")
        XCTAssertEqual(forms[4], "файлов")
        XCTAssertEqual(forms[10], "файлов") // 11
        XCTAssertEqual(forms[20], "файл")   // 21
        XCTAssertEqual(forms[21], "файла")  // 22
    }

    func testSubtitlePrefersResolvedAppNameAndPluralizesFiles() {
        var summary = ItemSummary(
            title: "", charCount: 0, lineCount: 1, linkHost: nil, fileNames: ["a.txt"],
            imagePixelSize: nil, imageFormat: nil, colorHex: nil,
            sourceBundleId: "com.apple.finder", copiedAt: now, lastUsedAt: now,
            kind: .file(1), passwordComment: nil, pdfPageCount: nil, isRichText: false,
            sourceAppName: "Finder"
        )
        let one = RowPresentationBuilder.subtitle(for: summary, locale: locale, now: now)
        XCTAssertTrue(one.hasPrefix("Finder · \(L10n.relativeJustNow)"))
        summary.kind = .file(3)
        let three = RowPresentationBuilder.subtitle(for: summary, locale: locale, now: now)
        XCTAssertTrue(three.contains("3"))
        summary.sourceAppName = nil
        XCTAssertTrue(RowPresentationBuilder.subtitle(for: summary, locale: locale, now: now).lowercased().contains("finder"))
    }

    func testLegacyColorPasteboardTypeClassifiesAsColor() {
        let kind = ItemKindClassifier.classify(.init(
            isPassword: false, typeIdentifiers: ["NSColorPboardType"], plainText: nil, fileURLCount: 0
        ))
        XCTAssertEqual(kind, .color)
    }

    func testColorHexAndImageFormat() {
        XCTAssertEqual(HistoryItemSummaryBuilder.hex(for: NSColor(srgbRed: 1, green: 0.5, blue: 0, alpha: 1)), "#FF8000")
        XCTAssertEqual(HistoryItemSummaryBuilder.imageFormat(from: ["public.jpeg"]), "JPEG")
        XCTAssertEqual(HistoryItemSummaryBuilder.imageFormat(from: ["public.tiff"]), "TIFF")
        XCTAssertEqual(HistoryItemSummaryBuilder.imageFormat(from: ["public.png", "public.tiff"]), "PNG")
    }
}

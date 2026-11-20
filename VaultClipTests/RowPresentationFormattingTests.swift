//
// RowPresentationFormattingTests — compact age, plurals, app names, color/image facts (U05/U11).
//
import AppKit
import XCTest
@testable import VaultClip

final class RowPresentationFormattingTests: XCTestCase {
    private let ru = Locale(identifier: "ru_RU")
    private let en = Locale(identifier: "en_US")
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testRelativeTimeNeverSigned() {
        let cases: [(TimeInterval, String, String)] = [
            (10, "только что", "now"),
            (5 * 60, "5 мин", "5 min"),
            (2 * 3600, "2 ч", "2 h"),
            (3 * 86_400, "3 дн.", "3 d")
        ]
        for (ago, ruText, enText) in cases {
            let date = now.addingTimeInterval(-ago)
            XCTAssertEqual(RowPresentationBuilder.relativeTime(from: date, to: now, locale: ru), ruText)
            XCTAssertEqual(RowPresentationBuilder.relativeTime(from: date, to: now, locale: en), enText)
        }
        let future = now.addingTimeInterval(120)
        XCTAssertEqual(RowPresentationBuilder.relativeTime(from: future, to: now, locale: ru), "только что")
        let old = RowPresentationBuilder.relativeTime(from: now.addingTimeInterval(-30 * 86_400), to: now, locale: ru)
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
        XCTAssertEqual(RowPresentationBuilder.subtitle(for: summary, locale: ru, now: now), "Finder · только что · 1 файл")
        summary.kind = .file(3)
        XCTAssertTrue(RowPresentationBuilder.subtitle(for: summary, locale: ru, now: now).hasSuffix("3 файла"))
        summary.sourceAppName = nil
        XCTAssertTrue(RowPresentationBuilder.subtitle(for: summary, locale: en, now: now).hasPrefix("finder"))
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

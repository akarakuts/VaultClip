//
// RowPresentationCoverageTests — titles/subtitles for all kinds (U05).
//
import XCTest
@testable import VaultClip

final class RowPresentationCoverageTests: XCTestCase {
    private func summary(
        kind: ItemKind,
        title: String = "",
        linkHost: String? = nil,
        fileNames: [String] = [],
        imagePixelSize: CGSize? = nil,
        imageFormat: String? = nil,
        colorHex: String? = nil,
        sourceBundleId: String? = "com.apple.Safari",
        passwordComment: String? = nil,
        pdfPageCount: Int? = nil,
        isRichText: Bool = false,
        charCount: Int = 0,
        lineCount: Int = 1
    ) -> ItemSummary {
        ItemSummary(
            title: title,
            charCount: charCount,
            lineCount: lineCount,
            linkHost: linkHost,
            fileNames: fileNames,
            imagePixelSize: imagePixelSize,
            imageFormat: imageFormat,
            colorHex: colorHex,
            sourceBundleId: sourceBundleId,
            copiedAt: Date(timeIntervalSince1970: 0),
            lastUsedAt: Date(timeIntervalSince1970: 10),
            kind: kind,
            passwordComment: passwordComment,
            pdfPageCount: pdfPageCount,
            isRichText: isRichText
        )
    }

    func testTitlesForEveryKind() {
        let locale = Locale.current
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password), locale: locale), L10n.rowKindPassword)
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password, passwordComment: "  "), locale: locale), L10n.rowKindPassword)
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password, passwordComment: "Bank"), locale: locale), "Bank")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .link, linkHost: "example.com"), locale: locale), "example.com")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .link, title: "https://x"), locale: locale), "https://x")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .file(1), fileNames: ["a.txt"]), locale: locale), "a.txt")
        XCTAssertEqual(
            RowPresentationBuilder.title(for: summary(kind: .file(3), fileNames: ["a.txt", "b"]), locale: locale),
            "a.txt · \(L10n.rowAndMore(2))"
        )
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .file(1)), locale: locale), L10n.rowKindFile)
        XCTAssertTrue(RowPresentationBuilder.title(for: summary(kind: .image, imagePixelSize: CGSize(width: 10, height: 20), imageFormat: "PNG"), locale: locale).contains("10×20"))
        XCTAssertTrue(RowPresentationBuilder.title(for: summary(kind: .image), locale: locale).contains(L10n.rowKindImage))
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, title: "doc.pdf"), locale: locale), "doc.pdf")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, pdfPageCount: 3), locale: locale), L10n.rowPdfPages(3))
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf), locale: locale), "PDF")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color, colorHex: "#ABC"), locale: locale), "#ABC")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color), locale: locale), "#000000")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .text, title: "line1\nline2"), locale: locale), "line1")
        let long = String(repeating: "x", count: 250)
        XCTAssertEqual(RowPresentationBuilder.collapseFirstLine(long).count, 200)
        let row = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .text, title: "hi", charCount: 2, lineCount: 2),
            locale: locale,
            now: now
        )
        XCTAssertTrue(row.subtitle.contains("Safari"))
        XCTAssertTrue(row.accessibilityLabel.contains("hi"))
        let pw = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .password, passwordComment: "x"),
            locale: locale,
            now: now
        )
        XCTAssertEqual(pw.accessibilityLabel, "x")
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .link, linkHost: "h"), locale: locale, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .file(2), fileNames: ["a"]), locale: locale, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .richText, title: "r", isRichText: true), locale: locale, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .text, title: "t", charCount: 12, lineCount: 1), locale: locale, now: now)
    }
}

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
        XCTAssertEqual(
            RowPresentationBuilder.title(
                for: summary(kind: .image, imagePixelSize: CGSize(width: 10, height: 20), imageFormat: "PNG"),
                locale: locale
            ),
            "10×20"
        )
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .image, imageFormat: "JPEG"), locale: locale), "JPEG")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .image), locale: locale), L10n.rowKindImage)
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, title: "doc.pdf"), locale: locale), "doc.pdf")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, pdfPageCount: 3), locale: locale), L10n.rowPdfPages(3))
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf), locale: locale), "PDF")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color, colorHex: "#ABC"), locale: locale), "#ABC")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color), locale: locale), "#000000")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .text, title: "line1\nline2"), locale: locale), "line1 — line2")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .richText, title: "A\nB"), locale: locale), "A — B")
        let long = String(repeating: "x", count: 250)
        XCTAssertEqual(RowPresentationBuilder.collapseFirstLine(long).count, 200)
        let row = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .text, title: "hi", charCount: 2, lineCount: 2),
            locale: locale,
            now: now
        )
        XCTAssertEqual(row.sourceName, "Safari")
        XCTAssertEqual(row.metaText, L10n.rowMetaLines(2))
        XCTAssertTrue(row.subtitle.contains("Safari"))
        XCTAssertTrue(row.accessibilityLabel.contains("hi"))
        let imageRow = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .image, imagePixelSize: CGSize(width: 8, height: 8), imageFormat: "PNG"),
            locale: locale,
            now: now
        )
        XCTAssertEqual(imageRow.title, "8×8")
        XCTAssertEqual(imageRow.metaText, "PNG")
        XCTAssertFalse(imageRow.accessibilityLabel.contains(L10n.rowKindImage))
        let pdfRow = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .pdf, title: "report.pdf", pdfPageCount: 4),
            locale: locale,
            now: now
        )
        XCTAssertEqual(pdfRow.title, "report.pdf")
        XCTAssertEqual(pdfRow.metaText, L10n.rowPdfPages(4))
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

    func testPasswordNeverLeaksSecretIntoPresentation() {
        let locale = Locale.current
        let now = Date(timeIntervalSince1970: 100)
        let secret = "hunter2-secret"
        let row = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .password, title: secret, passwordComment: "Bank"),
            locale: locale,
            now: now
        )
        XCTAssertEqual(row.title, "Bank")
        XCTAssertEqual(row.accessibilityLabel, "Bank")
        XCTAssertFalse(row.title.contains(secret))
        XCTAssertFalse(row.subtitle.contains(secret))
        XCTAssertFalse(row.accessibilityLabel.contains(secret))
    }
}

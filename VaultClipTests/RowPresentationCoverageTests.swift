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
        let en = Locale(identifier: "en_US")
        let ru = Locale(identifier: "ru_RU")
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password), locale: en), "Password")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password, passwordComment: "  "), locale: ru), "Пароль")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .password, passwordComment: "Bank"), locale: en), "Bank")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .link, linkHost: "example.com"), locale: en), "example.com")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .link, title: "https://x"), locale: en), "https://x")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .file(1), fileNames: ["a.txt"]), locale: en), "a.txt")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .file(3), fileNames: ["a.txt", "b"]), locale: en), "a.txt · and 2 more")
        XCTAssertTrue(RowPresentationBuilder.title(for: summary(kind: .file(3), fileNames: ["a.txt", "b"]), locale: ru).contains("ещё"))
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .file(1)), locale: en), "File")
        XCTAssertTrue(RowPresentationBuilder.title(for: summary(kind: .image, imagePixelSize: CGSize(width: 10, height: 20), imageFormat: "PNG"), locale: en).contains("10×20"))
        XCTAssertTrue(RowPresentationBuilder.title(for: summary(kind: .image), locale: ru).contains("Изображение"))
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, title: "doc.pdf"), locale: en), "doc.pdf")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, pdfPageCount: 3), locale: en), "PDF · 3 pages")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf, pdfPageCount: 3), locale: ru), "PDF · 3 стр.")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .pdf), locale: en), "PDF")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color, colorHex: "#ABC"), locale: en), "#ABC")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .color), locale: en), "#000000")
        XCTAssertEqual(RowPresentationBuilder.title(for: summary(kind: .text, title: "line1\nline2"), locale: en), "line1")
        let long = String(repeating: "x", count: 250)
        XCTAssertEqual(RowPresentationBuilder.collapseFirstLine(long).count, 200)
        let row = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .text, title: "hi", charCount: 2, lineCount: 2),
            locale: en,
            now: now
        )
        XCTAssertTrue(row.subtitle.contains("Safari"))
        XCTAssertTrue(row.accessibilityLabel.contains("hi"))
        let pw = RowPresentationBuilder.presentation(
            id: UUID(),
            summary: summary(kind: .password, passwordComment: "x"),
            locale: en,
            now: now
        )
        XCTAssertEqual(pw.accessibilityLabel, "x")
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .link, linkHost: "h"), locale: en, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .file(2), fileNames: ["a"]), locale: ru, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .richText, title: "r", isRichText: true), locale: en, now: now)
        _ = RowPresentationBuilder.subtitle(for: summary(kind: .text, title: "t", charCount: 12, lineCount: 1), locale: ru, now: now)
    }
}

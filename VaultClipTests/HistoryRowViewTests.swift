//
// HistoryRowViewTests — leading artwork and fixed row height (U11).
//
import XCTest
@testable import VaultClip

final class HistoryRowViewTests: XCTestCase {
    func testLeadingArtworkByKind() {
        XCTAssertNotNil(LeadingArtwork.image(for: .password, sourceBundleId: nil))
        XCTAssertNotNil(LeadingArtwork.image(for: .link, sourceBundleId: nil))
        XCTAssertNotNil(LeadingArtwork.image(for: .image, sourceBundleId: nil))
        XCTAssertNotNil(LeadingArtwork.image(for: .text, sourceBundleId: nil))
    }

    func testRowHeightFromTheme() {
        let height = PanelTheme.rowHeight(for: .m)
        XCTAssertGreaterThanOrEqual(height, 36)
    }

    func testThumbnailCacheDoesNotWriteTempFiles() {
        let tmp = FileManager.default.temporaryDirectory
        let before = (try? FileManager.default.contentsOfDirectory(atPath: tmp.path)) ?? []
        let png = NSImage(size: NSSize(width: 32, height: 32))
        png.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 32, height: 32).fill()
        png.unlockFocus()
        let tiff = png.tiffRepresentation!
        _ = ThumbnailMemoryCache.thumbnail(from: tiff, maxPixelSize: 16)
        let after = (try? FileManager.default.contentsOfDirectory(atPath: tmp.path)) ?? []
        XCTAssertEqual(Set(before), Set(after))
    }
}

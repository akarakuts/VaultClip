//
// PreviewMetadataTests — formatted metadata (U22).
//
import XCTest
@testable import VaultClip

final class PreviewMetadataTests: XCTestCase {
    func testFallsBackToBundleLastComponent() {
        let model = PreviewMetadataFormatter.format(
            appName: nil,
            bundleId: "com.apple.Safari",
            copiedAt: Date(timeIntervalSince1970: 0),
            lastUsedAt: Date(timeIntervalSince1970: 10),
            byteCount: 2048,
            typeIdentifiers: ["public.utf8-plain-text"],
            locale: Locale(identifier: "en_US"),
            now: Date(timeIntervalSince1970: 100)
        )
        XCTAssertEqual(model.appName, "Safari")
        XCTAssertFalse(model.sizeText.isEmpty)
        XCTAssertEqual(model.typeIdentifiers.count, 1)
    }
}

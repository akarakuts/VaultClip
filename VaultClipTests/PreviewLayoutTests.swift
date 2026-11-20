//
// PreviewLayoutTests — side/bottom thresholds (U21).
//
import XCTest
@testable import VaultClip

final class PreviewLayoutTests: XCTestCase {
    func testWidePanelSideBySide() {
        let result = PreviewLayout.layout(PreviewLayoutInput(
            panelWidth: 800, panelHeight: 600, position: .right, previewVisible: true, listFraction: nil
        ))
        XCTAssertEqual(result?.axis, .horizontal)
        XCTAssertGreaterThanOrEqual(result!.listSize, PreviewLayout.minListWidth)
        XCTAssertGreaterThanOrEqual(result!.previewSize, PreviewLayout.minPreviewWidth)
    }

    func testNarrowPanelStacksVertically() {
        let result = PreviewLayout.layout(PreviewLayoutInput(
            panelWidth: 500, panelHeight: 600, position: .right, previewVisible: true, listFraction: nil
        ))
        XCTAssertEqual(result?.axis, .vertical)
    }

    func testTopPositionForcesSide() {
        let result = PreviewLayout.layout(PreviewLayoutInput(
            panelWidth: 500, panelHeight: 400, position: .top, previewVisible: true, listFraction: nil
        ))
        XCTAssertEqual(result?.axis, .horizontal)
    }

    func testHiddenPreviewNil() {
        XCTAssertNil(PreviewLayout.layout(PreviewLayoutInput(
            panelWidth: 800, panelHeight: 600, position: .left, previewVisible: false, listFraction: nil
        )))
    }
}

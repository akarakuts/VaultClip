//
// UIGuidelinesRegistryTests — docs shortcut table matches registry (U37).
//
import XCTest
@testable import VaultClip

final class UIGuidelinesRegistryTests: XCTestCase {
    func testGuidelinesDocumentListsEveryCommandID() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("docs/ui-guidelines.md")
        let text = try String(contentsOf: url, encoding: .utf8)
        for id in PanelCommandID.allCases {
            XCTAssertTrue(
                text.contains(id.rawValue) || text.contains(String(describing: id)),
                "docs/ui-guidelines.md missing command \(id.rawValue)"
            )
        }
    }
}

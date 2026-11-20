//
// CheatSheetModelTests — full registry coverage (U26).
//
import XCTest
@testable import VaultClip

final class CheatSheetModelTests: XCTestCase {
    func testContainsAllCommands() {
        let entries = CheatSheetModel.entries()
        XCTAssertTrue(CheatSheetModel.containsAllRegistryCommands(entries))
    }
}

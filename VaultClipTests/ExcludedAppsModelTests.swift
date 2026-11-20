//
// ExcludedAppsModelTests — add/remove without self/dupes (U32).
//
import XCTest
@testable import VaultClip

final class ExcludedAppsModelTests: XCTestCase {
    func testAddRemove() {
        let selfId = "com.karakuts.VaultClip"
        var list: [String] = []
        list = ExcludedAppsModel.add("com.apple.Safari", to: list, selfBundleId: selfId)
        list = ExcludedAppsModel.add("com.apple.Safari", to: list, selfBundleId: selfId)
        list = ExcludedAppsModel.add(selfId, to: list, selfBundleId: selfId)
        XCTAssertEqual(list, ["com.apple.Safari"])
        list = ExcludedAppsModel.remove("com.apple.Safari", from: list)
        XCTAssertTrue(list.isEmpty)
    }
}

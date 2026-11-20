//
// SettingsStoreTests — round-trip apply (U29).
//
import XCTest
@testable import VaultClip

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testApplyAndDefaults() {
        let store = SettingsStore(settings: .default)
        XCTAssertEqual(store.statusItemClickMode, .openPanel)
        XCTAssertFalse(store.previewVisible)
        store.statusItemClickMode = .openMenu
        XCTAssertEqual(store.statusItemClickMode, .openMenu)
        store.recentMenuCount = 10
        XCTAssertEqual(store.recentMenuCount, 10)
    }
}

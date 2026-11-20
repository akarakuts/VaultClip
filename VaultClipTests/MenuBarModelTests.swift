//
// MenuBarModelTests — recents and pause auto-resume (U28).
//
import XCTest
@testable import VaultClip

final class MenuBarModelTests: XCTestCase {
    func testExcludesPasswordsAndLimits() {
        let items = [
            (id: UUID(), kind: ItemKind.text, isPassword: false, title: "a"),
            (id: UUID(), kind: ItemKind.password, isPassword: true, title: "secret"),
            (id: UUID(), kind: ItemKind.link, isPassword: false, title: "b"),
            (id: UUID(), kind: ItemKind.image, isPassword: false, title: "c")
        ]
        let recent = MenuBarModel.recentItems(from: items, limit: 2)
        XCTAssertEqual(recent.count, 2)
        XCTAssertFalse(recent.contains { $0.kind == .password })
    }

    func testPauseAutoResume() {
        let now = Date(timeIntervalSince1970: 1000)
        var state = CapturePauseState.apply(preset: .minutes(5), now: now)
        XCTAssertTrue(state.isPaused(at: now.addingTimeInterval(60)))
        state = state.autoResumed(at: now.addingTimeInterval(5 * 60 + 1))
        XCTAssertFalse(state.isPaused(at: now.addingTimeInterval(5 * 60 + 1)))
    }
}

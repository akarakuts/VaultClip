//
// HotKeyCaptureStateTests — validator message mapping (U31).
//
import XCTest
@testable import VaultClip

final class HotKeyCaptureStateTests: XCTestCase {
    func testMessages() {
        XCTAssertNil(HotKeyCaptureState.message(for: .ok))
        XCTAssertEqual(HotKeyCaptureState.phase(after: .needsModifier), .invalid(message: L10n.hotkeyErrorNeedsModifier))
        XCTAssertEqual(HotKeyCaptureState.phase(after: .ok), .valid)
    }
}

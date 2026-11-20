//
// PreviewUpdateDebouncerTests — cancel superseded work (U21).
//
import XCTest
@testable import VaultClip

final class PreviewUpdateDebouncerTests: XCTestCase {
    func testOnlyLatestGenerationRuns() {
        let scheduler = PreviewImmediateScheduler()
        let debouncer = PreviewUpdateDebouncer(scheduler: scheduler)
        var ran: [UInt64] = []
        let g1 = debouncer.schedule { ran.append($0) }
        let g2 = debouncer.schedule { ran.append($0) }
        scheduler.fireAllPending()
        XCTAssertEqual(ran, [g2])
        XCTAssertNotEqual(g1, g2)
    }
}

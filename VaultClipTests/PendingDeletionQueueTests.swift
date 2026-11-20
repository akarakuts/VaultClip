//
// PendingDeletionQueueTests — undo window and flush (U18).
//
import XCTest
@testable import VaultClip

final class PendingDeletionQueueTests: XCTestCase {
    func testUndoRestoresHiddenIds() {
        let scheduler = ImmediateTestScheduler()
        let queue = PendingDeletionQueue(scheduler: scheduler, now: { Date(timeIntervalSince1970: 1000) })
        let id = UUID()
        queue.enqueue(itemIds: [id], originalIndexes: [0])
        XCTAssertTrue(queue.hiddenItemIds.contains(id))
        XCTAssertNotNil(queue.undoLast())
        XCTAssertFalse(queue.hiddenItemIds.contains(id))
    }

    func testFlushCommits() {
        let scheduler = ImmediateTestScheduler()
        var committed: [UUID] = []
        let queue = PendingDeletionQueue(scheduler: scheduler, now: { Date(timeIntervalSince1970: 1000) })
        queue.onCommit = { committed.append(contentsOf: $0) }
        let id = UUID()
        queue.enqueue(itemIds: [id], originalIndexes: [2])
        queue.flushAll()
        XCTAssertEqual(committed, [id])
        XCTAssertTrue(queue.hiddenItemIds.isEmpty)
    }
}

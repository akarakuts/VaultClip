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

    func testTimeoutCommitAndMultipleBatches() {
        let scheduler = ImmediateTestScheduler()
        var committed: [[UUID]] = []
        let queue = PendingDeletionQueue(scheduler: scheduler, now: { Date(timeIntervalSince1970: 1000) })
        queue.onCommit = { committed.append($0) }
        let a = UUID(), b = UUID()
        let batch1 = queue.enqueue(itemIds: [a], originalIndexes: [0])
        let batch2 = queue.enqueue(itemIds: [b], originalIndexes: [1])
        XCTAssertEqual(queue.hiddenItemIds.count, 2)
        scheduler.fireAll()
        XCTAssertEqual(Set(committed.flatMap { $0 }), Set([a, b]))
        XCTAssertTrue(queue.hiddenItemIds.isEmpty)
        _ = batch1
        _ = batch2
        XCTAssertNil(queue.undoLast())
    }

    func testUndoCancelsScheduledCommit() {
        let scheduler = ImmediateTestScheduler()
        var committed: [UUID] = []
        let queue = PendingDeletionQueue(scheduler: scheduler, now: { Date(timeIntervalSince1970: 1000) })
        queue.onCommit = { committed.append(contentsOf: $0) }
        let id = UUID()
        let batch = queue.enqueue(itemIds: [id], originalIndexes: [0])
        XCTAssertEqual(batch.itemIds, [id])
        XCTAssertNotNil(queue.undoLast())
        scheduler.fireAll()
        XCTAssertTrue(committed.isEmpty)
        XCTAssertFalse(queue.hiddenItemIds.contains(id))
    }

    func testDispatchSchedulerCancelDoesNotCommit() {
        let scheduler = PendingDeletionDispatchScheduler()
        var committed: [UUID] = []
        let queue = PendingDeletionQueue(scheduler: scheduler, now: Date.init)
        queue.onCommit = { committed.append(contentsOf: $0) }
        let id = UUID()
        queue.enqueue(itemIds: [id], originalIndexes: [0])
        XCTAssertTrue(queue.hiddenItemIds.contains(id))
        XCTAssertNotNil(queue.undoLast())
        let expectation = expectation(description: "wait past undo window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(committed.isEmpty)
    }

    func testFlushEmptyIsNoOp() {
        let scheduler = ImmediateTestScheduler()
        var committed = 0
        let queue = PendingDeletionQueue(scheduler: scheduler)
        queue.onCommit = { _ in committed += 1 }
        queue.flushAll()
        XCTAssertEqual(committed, 0)
        XCTAssertNil(queue.undoLast())
    }
}

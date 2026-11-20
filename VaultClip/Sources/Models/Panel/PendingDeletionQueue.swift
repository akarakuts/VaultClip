//
// PendingDeletionQueue — soft-delete with undo window before file removal (U18).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct PendingDeletionBatch: Equatable {
    var id: UUID
    var itemIds: [UUID]
    /// Original indexes in the history array for restore order.
    var originalIndexes: [Int]
    var deadline: Date
}

protocol PendingDeletionScheduling: AnyObject {
    func schedule(after delay: TimeInterval, execute: @escaping () -> Void) -> UUID
    func cancel(_ token: UUID)
}

final class ImmediateTestScheduler: PendingDeletionScheduling {
    private var tasks: [UUID: () -> Void] = [:]
    func schedule(after delay: TimeInterval, execute: @escaping () -> Void) -> UUID {
        let id = UUID()
        tasks[id] = execute
        _ = delay
        return id
    }
    func cancel(_ token: UUID) { tasks[token] = nil }
    func fire(_ token: UUID) {
        let task = tasks.removeValue(forKey: token)
        task?()
    }
    func fireAll() {
        let all = tasks
        tasks.removeAll()
        all.values.forEach { $0() }
    }
}

final class PendingDeletionDispatchScheduler: PendingDeletionScheduling {
    private var workItems: [UUID: DispatchWorkItem] = [:]
    func schedule(after delay: TimeInterval, execute: @escaping () -> Void) -> UUID {
        let id = UUID()
        let work = DispatchWorkItem(block: execute)
        workItems[id] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        return id
    }
    func cancel(_ token: UUID) {
        workItems.removeValue(forKey: token)?.cancel()
    }
}

final class PendingDeletionQueue {
    static let undoWindow: TimeInterval = 8

    private(set) var batches: [PendingDeletionBatch] = []
    private var hiddenIds = Set<UUID>()
    private var tokens: [UUID: UUID] = [:]
    private let scheduler: PendingDeletionScheduling
    private let now: () -> Date
    var onCommit: (([UUID]) -> Void)?

    init(scheduler: PendingDeletionScheduling, now: @escaping () -> Date = Date.init) {
        self.scheduler = scheduler
        self.now = now
    }

    var hiddenItemIds: Set<UUID> { hiddenIds }

    @discardableResult
    func enqueue(itemIds: [UUID], originalIndexes: [Int]) -> PendingDeletionBatch {
        precondition(itemIds.count == originalIndexes.count)
        let batch = PendingDeletionBatch(
            id: UUID(),
            itemIds: itemIds,
            originalIndexes: originalIndexes,
            deadline: now().addingTimeInterval(Self.undoWindow)
        )
        batches.append(batch)
        itemIds.forEach { hiddenIds.insert($0) }
        let token = scheduler.schedule(after: Self.undoWindow) { [weak self] in
            self?.commit(batchId: batch.id)
        }
        tokens[batch.id] = token
        return batch
    }

    @discardableResult
    func undoLast() -> PendingDeletionBatch? {
        guard let batch = batches.popLast() else { return nil }
        if let token = tokens.removeValue(forKey: batch.id) {
            scheduler.cancel(token)
        }
        batch.itemIds.forEach { hiddenIds.remove($0) }
        return batch
    }

    func flushAll() {
        let pending = batches
        batches.removeAll()
        for batch in pending {
            if let token = tokens.removeValue(forKey: batch.id) {
                scheduler.cancel(token)
            }
            commit(batchId: batch.id, alreadyRemovedFromQueue: true, batch: batch)
        }
    }

    private func commit(batchId: UUID, alreadyRemovedFromQueue: Bool = false, batch: PendingDeletionBatch? = nil) {
        let resolved: PendingDeletionBatch?
        if alreadyRemovedFromQueue {
            resolved = batch
        } else {
            resolved = batches.first(where: { $0.id == batchId })
            batches.removeAll { $0.id == batchId }
            if let token = tokens.removeValue(forKey: batchId) {
                scheduler.cancel(token)
            }
        }
        guard let resolved else { return }
        resolved.itemIds.forEach { hiddenIds.remove($0) }
        onCommit?(resolved.itemIds)
    }
}

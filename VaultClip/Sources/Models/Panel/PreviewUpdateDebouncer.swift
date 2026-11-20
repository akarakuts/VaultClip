//
// PreviewUpdateDebouncer — 50 ms debounce with generation cancel (U21).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

protocol PreviewDebounceScheduling: AnyObject {
    func schedule(after delay: TimeInterval, execute: @escaping () -> Void) -> UUID
    func cancel(_ token: UUID)
}

final class PreviewImmediateScheduler: PreviewDebounceScheduling {
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
    func fireAllPending() {
        let all = tasks
        tasks.removeAll()
        all.values.forEach { $0() }
    }
}

final class PreviewUpdateDebouncer {
    static let delay: TimeInterval = 0.05

    private let scheduler: PreviewDebounceScheduling
    private var token: UUID?
    private var generation: UInt64 = 0

    init(scheduler: PreviewDebounceScheduling) {
        self.scheduler = scheduler
    }

    /// Schedules work; returns the generation that will run if not superseded.
    @discardableResult
    func schedule(_ work: @escaping (_ generation: UInt64) -> Void) -> UInt64 {
        if let token {
            scheduler.cancel(token)
        }
        generation &+= 1
        let gen = generation
        token = scheduler.schedule(after: Self.delay) { [weak self] in
            guard let self, self.generation == gen else { return }
            work(gen)
        }
        return gen
    }

    func cancel() {
        if let token {
            scheduler.cancel(token)
        }
        token = nil
        generation &+= 1
    }

    var currentGeneration: UInt64 { generation }
}

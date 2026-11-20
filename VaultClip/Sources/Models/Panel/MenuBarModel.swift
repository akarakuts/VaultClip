//
// MenuBarModel — status-menu recent items and pause states (U28).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct MenuBarRecentItem: Equatable, Identifiable {
    var id: UUID
    var title: String
    var kind: ItemKind
    var shortcutDigit: Int?
}

enum CapturePausePreset: Equatable {
    case minutes(Int)
    case untilRestart
    case untilResume
}

struct CapturePauseState: Equatable {
    var pausedUntil: Date?
    var untilRestart: Bool

    var isPaused: Bool {
        if untilRestart { return true }
        if let pausedUntil { return pausedUntil > Date() }
        return false
    }

    func isPaused(at now: Date) -> Bool {
        if untilRestart { return true }
        if let pausedUntil { return pausedUntil > now }
        return false
    }

    static func apply(preset: CapturePausePreset, now: Date = Date()) -> CapturePauseState {
        switch preset {
        case .minutes(let m):
            return CapturePauseState(pausedUntil: now.addingTimeInterval(TimeInterval(m * 60)), untilRestart: false)
        case .untilRestart:
            return CapturePauseState(pausedUntil: nil, untilRestart: true)
        case .untilResume:
            return CapturePauseState(pausedUntil: .distantFuture, untilRestart: false)
        }
    }

    func autoResumed(at now: Date) -> CapturePauseState {
        guard let pausedUntil, !untilRestart, pausedUntil <= now else { return self }
        return CapturePauseState(pausedUntil: nil, untilRestart: false)
    }
}

enum MenuBarModel {
    static func recentItems(
        from items: [(id: UUID, kind: ItemKind, isPassword: Bool, title: String)],
        limit: Int
    ) -> [MenuBarRecentItem] {
        var result: [MenuBarRecentItem] = []
        var digit = 1
        for item in items where !item.isPassword && item.kind != .password {
            let title = String(item.title.prefix(40))
            let shortcut = digit <= 5 ? digit : nil
            result.append(MenuBarRecentItem(id: item.id, title: title, kind: item.kind, shortcutDigit: shortcut))
            digit += 1
            if result.count >= limit { break }
        }
        return result
    }
}

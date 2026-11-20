//
// PanelFocusGuard — suspend panel auto-close while modal prompts are up.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Why the history panel is being hidden — drives focus restore in HistoryWindowController.
enum PanelCloseReason {
    case userAction
    case paste
    case appDeactivated
}

/// Pure rules for closing the panel and restoring the previous frontmost app.
enum PanelVisibilityPolicy {
    static func shouldClose(reason: PanelCloseReason, isShown: Bool, isSuspended: Bool) -> Bool {
        guard isShown else { return false }
        if reason == .appDeactivated {
            return !isSuspended
        }
        return true
    }

    static func shouldRestoreFocus(reason: PanelCloseReason) -> Bool {
        switch reason {
        case .userAction, .paste:
            return true
        case .appDeactivated:
            return false
        }
    }
}

/// Nested suspend counter for modal alerts / prompts shown over an open panel (main thread only).
enum PanelFocusGuard {
    private static var depth = 0

    static var isSuspended: Bool { depth > 0 }

    static func suspend() {
        dispatchPrecondition(condition: .onQueue(.main))
        depth += 1
    }

    static func resume() {
        dispatchPrecondition(condition: .onQueue(.main))
        depth = max(0, depth - 1)
    }

    static func withSuspended<T>(_ body: () throws -> T) rethrows -> T {
        suspend()
        defer { resume() }
        return try body()
    }

    #if DEBUG
    static func resetForTests() {
        dispatchPrecondition(condition: .onQueue(.main))
        depth = 0
    }
    #endif
}

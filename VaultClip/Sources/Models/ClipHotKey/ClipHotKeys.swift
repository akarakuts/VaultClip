//
// ClipHotKeys — global Carbon toggle only; panel keys use PanelLocalKeyMonitor (U04).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct ClipHotKeys {
    /// Global toggle — registered at launch.
    static var toggle = ClipHotKey(key: .v, modifiers: [.command, .shift], startsPaused: false)

    /// Panel no longer registers Carbon hot keys.
    static var panelScoped: [ClipHotKey] { [] }

    static func setPanelHotKeysActive(_ active: Bool) {
        // No-op: panel input is handled by PanelLocalKeyMonitor while visible.
        _ = active
    }
}

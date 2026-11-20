//
// StatusItemClickMode — menu-bar icon click behavior (U27).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum StatusItemClickMode: String, Codable, CaseIterable, Equatable {
    case openPanel
    case openMenu

    static let `default`: StatusItemClickMode = .openPanel
}

enum StatusItemPresentation {
    static func accessibilityTitle(isPaused: Bool) -> String {
        isPaused ? "VaultClip — захват приостановлен" : "VaultClip"
    }

    static func accessibilityTitleEnglish(isPaused: Bool) -> String {
        isPaused ? "VaultClip — capture paused" : "VaultClip"
    }

    /// Left-click should toggle panel only in openPanel mode.
    static func leftClickOpensPanel(mode: StatusItemClickMode) -> Bool {
        mode == .openPanel
    }
}

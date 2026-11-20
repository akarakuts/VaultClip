//
// FocusZone — keyboard focus regions inside the history panel (U03/U04).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum FocusZone: String, Hashable, CaseIterable {
    case search
    case list
    case preview
    case editor
    case palette
    case filters
}

//
// PreviewPlacement — embedded preview layout preference (U21/U30).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PreviewPlacement: String, Codable, CaseIterable, Equatable {
    case automatic
    case trailing
    case bottom
}

//
// PanelAppearance — history panel chrome theme (system / light / dark / liquid glass).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PanelAppearance: String, Codable, CaseIterable, Equatable {
    case system
    case light
    case dark
    case liquidGlass
}

extension PanelAppearance {
    var settingsTitle: String {
        switch self {
        case .system: return L10n.settingsPanelAppearanceSystem
        case .light: return L10n.settingsPanelAppearanceLight
        case .dark: return L10n.settingsPanelAppearanceDark
        case .liquidGlass: return L10n.settingsPanelAppearanceLiquidGlass
        }
    }
}
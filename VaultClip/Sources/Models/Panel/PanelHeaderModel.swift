//
// PanelHeaderModel — header chrome visibility by tab (U08).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct PanelHeaderModel: Equatable {
    var showsFilterBar: Bool
    var showsPreviewButton: Bool
    var searchPlaceholder: String
    var searchTooltip: String
}

enum PanelHeaderPresenter {
    static let searchDebounceMs: Int = 60

    static func model(
        tab: HistoryListMode,
        filtersVisiblePreference: Bool = true,
        locale: Locale = .current
    ) -> PanelHeaderModel {
        _ = locale
        let passwords = tab == .passwords
        return PanelHeaderModel(
            showsFilterBar: !passwords && filtersVisiblePreference,
            showsPreviewButton: true,
            searchPlaceholder: passwords ? L10n.searchPlaceholderPasswords : L10n.searchPlaceholder,
            searchTooltip: passwords ? L10n.searchTooltipPasswords : L10n.searchTooltip
        )
    }
}

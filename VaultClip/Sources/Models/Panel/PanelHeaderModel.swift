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
        let isRU = locale.language.languageCode?.identifier == "ru"
        return PanelHeaderModel(
            showsFilterBar: tab != .passwords && filtersVisiblePreference,
            showsPreviewButton: true,
            searchPlaceholder: isRU ? "Поиск" : "Search",
            searchTooltip: isRU
                ? "Можно уточнить: type:ссылка app:Safari"
                : "You can refine: type:link app:Safari"
        )
    }
}

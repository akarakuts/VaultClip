//
// PanelEmptyStateModel — ContentUnavailable-style empty/loading states (U10).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct PanelEmptyStateModel: Equatable {
    var symbolName: String
    var title: String
    var description: String
    var primaryButtonTitle: String?
}

enum PanelEmptyStatePresenter {
    static func present(
        kind: PanelEmptyKind?,
        isLoading: Bool,
        isCapturePaused: Bool,
        filtersActive: Bool,
        otherTabHitCount: Int?,
        otherTab: HistoryListMode?,
        locale: Locale = .current
    ) -> PanelEmptyStateModel? {
        _ = locale // catalog follows Bundle/system; kept for call-site compatibility / tests
        if isLoading {
            return PanelEmptyStateModel(
                symbolName: "arrow.triangle.2.circlepath",
                title: L10n.historyLoading,
                description: "",
                primaryButtonTitle: nil
            )
        }
        guard let kind else { return nil }
        switch kind {
        case .history:
            if isCapturePaused {
                return PanelEmptyStateModel(
                    symbolName: "pause.circle",
                    title: L10n.emptyHistoryPausedTitle,
                    description: L10n.emptyHistoryPausedBody,
                    primaryButtonTitle: L10n.emptyHistoryResume
                )
            }
            return PanelEmptyStateModel(
                symbolName: "doc.on.clipboard",
                title: L10n.emptyHistoryTitle,
                description: L10n.emptyHistoryBody,
                primaryButtonTitle: nil
            )
        case .favorites:
            return PanelEmptyStateModel(
                symbolName: "star",
                title: L10n.emptyFavoritesTitle,
                description: L10n.emptyFavoritesBody,
                primaryButtonTitle: nil
            )
        case .passwords:
            return PanelEmptyStateModel(
                symbolName: "key",
                title: L10n.emptyPasswordsTitle,
                description: "\(L10n.emptyPasswordsBodyManagers)\n\(L10n.emptyPasswordsBodySave)",
                primaryButtonTitle: nil
            )
        case .noResults(let query):
            var description = ""
            // Query-only miss still needs a click: Esc is easy to miss with a mouse.
            var button: String?
            if filtersActive {
                button = L10n.emptyClearFilters
            } else if !query.isEmpty {
                button = L10n.searchClear
            }
            if let count = otherTabHitCount, let tab = otherTab, count > 0 {
                let tabName: String
                switch tab {
                case .history: tabName = L10n.tabHistory
                case .favorites: tabName = L10n.tabFavorites
                case .passwords: tabName = L10n.tabPasswords
                }
                description = L10n.emptyNoResultsOtherTab(count: count, tab: tabName)
                button = L10n.emptyGo
            }
            return PanelEmptyStateModel(
                symbolName: "magnifyingglass",
                title: L10n.emptyNoResultsTitle(query),
                description: description,
                primaryButtonTitle: button
            )
        }
    }
}

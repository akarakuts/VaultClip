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
        let ru = locale.language.languageCode?.identifier == "ru"
        if isLoading {
            return PanelEmptyStateModel(
                symbolName: "arrow.triangle.2.circlepath",
                title: ru ? "Загрузка истории…" : "Loading history…",
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
                    title: ru ? "Захват приостановлен" : "Capture paused",
                    description: ru
                        ? "История пуста, и новые копии не записываются."
                        : "History is empty and new copies are not being recorded.",
                    primaryButtonTitle: ru ? "Возобновить" : "Resume"
                )
            }
            return PanelEmptyStateModel(
                symbolName: "doc.on.clipboard",
                title: ru ? "Здесь появится всё, что вы копируете" : "Everything you copy will show up here",
                description: ru
                    ? "Скопируйте текст, ссылку или картинку в любом приложении"
                    : "Copy text, a link, or an image in any app",
                primaryButtonTitle: nil
            )
        case .favorites:
            return PanelEmptyStateModel(
                symbolName: "star",
                title: ru ? "Нет избранного" : "No favorites",
                description: ru
                    ? "Выделите элемент и нажмите ⌘D или ★"
                    : "Select an item and press ⌘D or ★",
                primaryButtonTitle: nil
            )
        case .passwords:
            return PanelEmptyStateModel(
                symbolName: "key",
                title: ru ? "Нет сохранённых паролей" : "No saved passwords",
                description: ru
                    ? "Копии из менеджеров паролей не записываются. Чтобы сохранить пароль, выберите элемент → ⌘K → «Сохранить в пароли»"
                    : "Copies from password managers are never recorded. To save a password, select an item → ⌘K → Save to Passwords",
                primaryButtonTitle: nil
            )
        case .noResults(let query):
            var description = ""
            var button: String? = filtersActive ? (ru ? "Сбросить фильтры" : "Clear filters") : nil
            if let count = otherTabHitCount, let tab = otherTab, count > 0 {
                let tabName: String
                switch tab {
                case .history: tabName = ru ? "История" : "History"
                case .favorites: tabName = ru ? "Избранное" : "Favorites"
                case .passwords: tabName = ru ? "Пароли" : "Passwords"
                }
                description = ru
                    ? "Найдено \(count) во вкладке «\(tabName)»"
                    : "Found \(count) in “\(tabName)”"
                button = ru ? "Перейти" : "Go"
            }
            return PanelEmptyStateModel(
                symbolName: "magnifyingglass",
                title: ru ? "Ничего не найдено по «\(query)»" : "No results for “\(query)”",
                description: description,
                primaryButtonTitle: button
            )
        }
    }
}

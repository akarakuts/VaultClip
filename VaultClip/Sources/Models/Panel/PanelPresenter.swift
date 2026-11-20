//
// PanelPresenter — Foundation-only list rows, selection, empty states (U05).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PanelPresenter {

    static func present(_ input: PanelPresenterInput) -> PanelPresenterOutput {
        precondition(input.items.count == input.itemIds.count)

        if input.items.isEmpty {
            let empty: PanelEmptyKind
            if !input.searchQuery.isEmpty {
                empty = .noResults(query: input.searchQuery)
            } else {
                switch input.tab {
                case .history: empty = .history
                case .favorites: empty = .favorites
                case .passwords: empty = .passwords
                }
            }
            return PanelPresenterOutput(
                rows: [],
                selectedRowIndexes: [],
                totalCount: 0,
                visibleCount: 0,
                emptyKind: empty
            )
        }

        var rows: [PanelListRow] = []
        var selectedIndexes = IndexSet()
        var shortcut = 1

        let appendItem: (UUID, ItemSummary) -> Void = { id, summary in
            let presentation = RowPresentationBuilder.presentation(
                id: id,
                summary: summary,
                locale: input.locale,
                now: input.now
            )
            let number: Int? = shortcut <= 9 ? shortcut : (shortcut == 10 ? 0 : nil)
            if shortcut <= 10 { shortcut += 1 }
            let rowIndex = rows.count
            rows.append(.item(presentation, shortcutNumber: number))
            if input.selectedIds.contains(id) {
                selectedIndexes.insert(rowIndex)
            }
        }

        if input.groupByDay {
            let grouped = Dictionary(grouping: Array(zip(input.itemIds, input.items))) { pair -> DateComponents in
                input.calendar.dateComponents([.year, .month, .day], from: pair.1.lastUsedAt)
            }
            let keys = grouped.keys.sorted { lhs, rhs in
                let ld = input.calendar.date(from: lhs) ?? .distantPast
                let rd = input.calendar.date(from: rhs) ?? .distantPast
                return ld > rd
            }
            for key in keys {
                let dayItems = grouped[key] ?? []
                let title = dayHeaderTitle(components: key, calendar: input.calendar, locale: input.locale, now: input.now)
                let headerId = "\(key.year ?? 0)-\(key.month ?? 0)-\(key.day ?? 0)"
                rows.append(.header(id: headerId, title: title, count: dayItems.count))
                for (id, summary) in dayItems {
                    appendItem(id, summary)
                }
            }
        } else {
            for (id, summary) in zip(input.itemIds, input.items) {
                appendItem(id, summary)
            }
        }

        return PanelPresenterOutput(
            rows: rows,
            selectedRowIndexes: selectedIndexes,
            totalCount: input.items.count,
            visibleCount: input.items.count,
            emptyKind: nil
        )
    }

    private static func dayHeaderTitle(
        components: DateComponents,
        calendar: Calendar,
        locale: Locale,
        now: Date
    ) -> String {
        guard let date = calendar.date(from: components) else { return "" }
        if calendar.isDateInToday(date) {
            return locale.language.languageCode?.identifier == "ru" ? "Сегодня" : "Today"
        }
        if calendar.isDateInYesterday(date) {
            return locale.language.languageCode?.identifier == "ru" ? "Вчера" : "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.doesRelativeDateFormatting = false
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

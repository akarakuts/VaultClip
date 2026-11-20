//
// CheatSheetOverlayView — ⌘/ overlay of registry shortcuts grouped by command group (U26).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class CheatSheetOverlayView: PanelOverlayListView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func present() {
        presentOverlay()
        setAccessibilityIdentifier(Accessibility.identifiers.cheatSheet)
    }

    private func configure() {
        placeholder = Self.ru ? "Найти сочетание…" : "Filter shortcuts…"
        onQueryChange = { [weak self] query in self?.reload(query) }
        onActivateRow = { _ in }
    }

    private func reload(_ query: String) {
        var display: [PanelOverlayRow] = []
        var lastGroup: PanelCommandGroup?
        let order: [PanelCommandGroup] = [.item, .view, .filter, .app, .window]
        let entries = CheatSheetModel.entries(filter: query).enumerated().sorted {
            let l = order.firstIndex(of: $0.element.group) ?? 99
            let r = order.firstIndex(of: $1.element.group) ?? 99
            return l == r ? $0.offset < $1.offset : l < r
        }.map(\.element)
        for entry in entries {
            if entry.group != lastGroup {
                display.append(PanelOverlayRow(title: Self.title(for: entry.group), symbolName: nil, shortcut: nil, isEnabled: false, isHeader: true))
                lastGroup = entry.group
            }
            let symbol = PanelCommandRegistry.command(id: entry.id).symbolName
            display.append(PanelOverlayRow(title: entry.title, symbolName: symbol, shortcut: entry.shortcut, isEnabled: true))
        }
        setRows(display)
    }

    private static var ru: Bool { Locale.current.language.languageCode?.identifier == "ru" }

    private static func title(for group: PanelCommandGroup) -> String {
        switch group {
        case .item: return ru ? "Элемент и вставка" : "Item & paste"
        case .view: return ru ? "Вид и навигация" : "View & navigation"
        case .filter: return ru ? "Фильтры" : "Filters"
        case .app: return ru ? "Приложение" : "App"
        case .window: return ru ? "Окно" : "Window"
        }
    }
}

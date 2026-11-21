//
// CommandPaletteOverlayView — in-panel ⌘K action palette grouped by section (U25).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class CommandPaletteOverlayView: PanelOverlayListView {
    var onSelect: ((PanelCommandID) -> Void)?

    private var context = PanelCommandContext()
    private var commandIDs: [PanelCommandID?] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func present(context: PanelCommandContext) {
        self.context = context
        presentOverlay()
        setAccessibilityIdentifier(Accessibility.identifiers.commandPalette)
    }

    private func configure() {
        placeholder = L10n.paletteFilterPlaceholder
        onQueryChange = { [weak self] query in self?.reload(query: query) }
        onActivateRow = { [weak self] index in
            guard let self, let id = self.commandIDs[index] else { return }
            self.dismiss()
            self.onSelect?(id)
        }
    }

    private func reload(query: String) {
        let paletteRows = CommandPaletteBuilder.rows(context: context, query: query)
        var display: [PanelOverlayRow] = []
        var ids: [PanelCommandID?] = []
        var lastSection: CommandPaletteSection?
        // Headers only for the browse view; ranked results stay flat.
        let grouped = query.trimmingCharacters(in: .whitespaces).isEmpty
        for row in paletteRows {
            if grouped, row.section != lastSection {
                display.append(PanelOverlayRow(title: Self.title(for: row.section), symbolName: nil, shortcut: nil, isEnabled: false, isHeader: true))
                ids.append(nil)
                lastSection = row.section
            }
            let enabled: Bool
            if case .enabled = row.availability { enabled = true } else { enabled = false }
            display.append(PanelOverlayRow(title: row.title, symbolName: row.symbolName, shortcut: row.shortcut, isEnabled: enabled))
            ids.append(row.id)
        }
        commandIDs = ids
        setRows(display)
    }

    private static func title(for section: CommandPaletteSection) -> String {
        switch section {
        case .forSelection: return L10n.paletteGroupSelection
        case .view: return L10n.paletteGroupView
        case .filters: return L10n.paletteGroupFilters
        case .app: return L10n.paletteGroupApp
        }
    }
}

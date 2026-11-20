//
// CommandPaletteOverlayView — in-panel ⌘K action palette (U25).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class CommandPaletteOverlayView: NSView {
    var onSelect: ((PanelCommandID) -> Void)?
    var onDismiss: (() -> Void)?

    private let material = NSVisualEffectView()
    private let searchField = NSSearchField()
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private var rows: [CommandPaletteRow] = []
    private var selectedIndex = 0
    private var context = PanelCommandContext()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func present(context: PanelCommandContext) {
        self.context = context
        isHidden = false
        searchField.stringValue = ""
        reload(query: "")
        window?.makeFirstResponder(searchField)
        setAccessibilityIdentifier(Accessibility.identifiers.commandPalette)
    }

    func dismiss() {
        isHidden = true
        onDismiss?()
    }

    private func reload(query: String) {
        rows = CommandPaletteBuilder.rows(context: context, query: query)
        selectedIndex = 0
        table.reloadData()
        if !rows.isEmpty {
            table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = PanelTheme.Radius.palette
        layer?.masksToBounds = true
        isHidden = true

        material.material = .popover
        material.blendingMode = .withinWindow
        material.state = .active
        material.translatesAutoresizingMaskIntoConstraints = false
        addSubview(material)

        searchField.placeholderString = "Action or command…"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(queryChanged)
        addSubview(searchField)

        table.headerView = nil
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 28
        table.style = .plain
        table.target = self
        table.doubleAction = #selector(activateSelection)
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: leadingAnchor),
            material.trailingAnchor.constraint(equalTo: trailingAnchor),
            material.topAnchor.constraint(equalTo: topAnchor),
            material.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func queryChanged() {
        reload(query: searchField.stringValue)
    }

    @objc private func activateSelection() {
        let row = table.selectedRow
        guard rows.indices.contains(row) else { return }
        let item = rows[row]
        if case .enabled = item.availability {
            onSelect?(item.id)
            dismiss()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            dismiss()
            return
        }
        if event.keyCode == 36 { // Return
            activateSelection()
            return
        }
        if event.keyCode == 125 { // down
            moveSelection(1)
            return
        }
        if event.keyCode == 126 { // up
            moveSelection(-1)
            return
        }
        super.keyDown(with: event)
    }

    private func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        selectedIndex = min(max(0, selectedIndex + delta), rows.count - 1)
        table.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        table.scrollRowToVisible(selectedIndex)
    }
}

extension CommandPaletteOverlayView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = rows[row]
        let id = NSUserInterfaceItemIdentifier("PaletteRow")
        let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView) ?? {
            let c = NSTableCellView()
            c.identifier = id
            let label = NSTextField(labelWithString: "")
            label.translatesAutoresizingMaskIntoConstraints = false
            c.addSubview(label)
            c.textField = label
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -10),
                label.centerYAnchor.constraint(equalTo: c.centerYAnchor)
            ])
            return c
        }()
        let shortcut = item.shortcut.map { "  \($0)" } ?? ""
        cell.textField?.stringValue = "\(item.title)\(shortcut)"
        cell.textField?.textColor = {
            if case .enabled = item.availability { return .labelColor }
            return .secondaryLabelColor
        }()
        return cell
    }
}

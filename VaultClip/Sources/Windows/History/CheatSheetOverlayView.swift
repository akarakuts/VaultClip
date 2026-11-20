//
// CheatSheetOverlayView — ⌘/ overlay of registry shortcuts (U26).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class CheatSheetOverlayView: NSView {
    var onDismiss: (() -> Void)?
    private let material = NSVisualEffectView()
    private let searchField = NSSearchField()
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private var entries: [CheatSheetEntry] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func present() {
        isHidden = false
        searchField.stringValue = ""
        reload("")
        window?.makeFirstResponder(searchField)
        setAccessibilityIdentifier(Accessibility.identifiers.cheatSheet)
    }

    func dismiss() {
        isHidden = true
        onDismiss?()
    }

    private func reload(_ query: String) {
        entries = CheatSheetModel.entries(filter: query)
        table.reloadData()
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
        searchField.placeholderString = "Filter shortcuts…"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(queryChanged)
        addSubview(searchField)
        table.headerView = nil
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 24
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

    @objc private func queryChanged() { reload(searchField.stringValue) }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismiss()
            return
        }
        super.keyDown(with: event)
    }
}

extension CheatSheetOverlayView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int { entries.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let entry = entries[row]
        let id = NSUserInterfaceItemIdentifier("CheatRow")
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
        cell.textField?.stringValue = "\(entry.title)  \(entry.shortcut)"
        return cell
    }
}

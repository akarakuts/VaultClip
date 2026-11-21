//
// PanelOverlayListView — shared rounded overlay (search field + icon/title/shortcut list) for ⌘K and ⌘/ (U25/U26).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

struct PanelOverlayRow: Equatable {
    var title: String
    var symbolName: String?
    var shortcut: String?
    var isEnabled: Bool
    var isHeader: Bool = false
}

class PanelOverlayListView: NSView, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    var onDismiss: (() -> Void)?
    var onActivateRow: ((Int) -> Void)?
    var onQueryChange: ((String) -> Void)?

    let searchField = NSSearchField()
    private let material = NSVisualEffectView()
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private(set) var rows: [PanelOverlayRow] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    var placeholder: String {
        get { searchField.placeholderString ?? "" }
        set { searchField.placeholderString = newValue }
    }

    func presentOverlay() {
        isHidden = false
        superview?.addSubview(self, positioned: .above, relativeTo: nil)
        searchField.stringValue = ""
        onQueryChange?("")
        window?.makeFirstResponder(searchField)
    }

    func dismiss() {
        guard !isHidden else { return }
        isHidden = true
        onDismiss?()
    }

    func setRows(_ newRows: [PanelOverlayRow]) {
        rows = newRows
        table.reloadData()
        selectFirstSelectable(from: 0, step: 1)
    }

    var selectedRowIndex: Int { table.selectedRow }

    /// Keys forwarded by the panel monitor while the overlay is up; returns true when consumed.
    func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 53: dismiss(); return true
        case 36, 76: activateSelection(); return true
        case 125: moveSelection(1); return true
        case 126: moveSelection(-1); return true
        default: return false
        }
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = PanelTheme.Radius.palette
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        isHidden = true

        material.blendingMode = .withinWindow
        material.state = .active
        material.translatesAutoresizingMaskIntoConstraints = false
        addSubview(material)

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.delegate = self
        searchField.sendsSearchStringImmediately = true
        addSubview(searchField)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("OverlayColumn"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.backgroundColor = .clear
        table.style = .inset
        table.rowHeight = 26
        table.intercellSpacing = NSSize(width: 0, height: 2)
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.delegate = self
        table.dataSource = self
        table.target = self
        table.action = #selector(rowClicked)
        table.doubleAction = #selector(rowClicked)
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: leadingAnchor),
            material.trailingAnchor.constraint(equalTo: trailingAnchor),
            material.topAnchor.constraint(equalTo: topAnchor),
            material.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 6),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        syncPanelOverlayChrome()
    }

    func syncPanelOverlayChrome() {
        let style = PanelChromeStyleResolver.currentStyle(kind: .floating)
        material.material = style.usesSolidBackground ? .contentBackground : style.overlayListMaterial
    }

    override func updateLayer() {
        layer?.borderColor = NSColor.separatorColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    // ── Selection ──

    private func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        let start = table.selectedRow < 0 ? (delta > 0 ? -1 : rows.count) : table.selectedRow
        selectFirstSelectable(from: start + delta, step: delta)
    }

    private func selectFirstSelectable(from start: Int, step: Int) {
        var index = start
        while rows.indices.contains(index) {
            if !rows[index].isHeader {
                table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                table.scrollRowToVisible(index)
                return
            }
            index += step
        }
    }

    private func activateSelection() {
        let row = table.selectedRow
        guard rows.indices.contains(row), rows[row].isEnabled, !rows[row].isHeader else { return }
        onActivateRow?(row)
    }

    @objc private func rowClicked() {
        activateSelection()
    }

    // ── NSSearchFieldDelegate ──

    func controlTextDidChange(_ obj: Notification) {
        onQueryChange?(searchField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)): moveSelection(1); return true
        case #selector(NSResponder.moveUp(_:)): moveSelection(-1); return true
        case #selector(NSResponder.insertNewline(_:)): activateSelection(); return true
        case #selector(NSResponder.cancelOperation(_:)): dismiss(); return true
        default: return false
        }
    }

    // ── Table ──

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool { rows[row].isHeader }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { !rows[row].isHeader }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = rows[row]
        let id = NSUserInterfaceItemIdentifier("OverlayRow")
        let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? OverlayRowCell) ?? OverlayRowCell(identifier: id)
        cell.configure(item)
        return cell
    }
}

private final class OverlayRowCell: NSTableCellView {
    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let shortcut = NSTextField(labelWithString: "")

    init(identifier: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        self.identifier = identifier
        for view in [icon, title, shortcut] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        title.lineBreakMode = .byTruncatingTail
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        shortcut.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        shortcut.textColor = .secondaryLabelColor
        shortcut.alignment = .right
        shortcut.setContentCompressionResistancePriority(.required, for: .horizontal)
        icon.contentTintColor = .secondaryLabelColor
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.trailingAnchor.constraint(lessThanOrEqualTo: shortcut.leadingAnchor, constant: -8),
            shortcut.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            shortcut.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(_ row: PanelOverlayRow) {
        title.stringValue = row.title
        shortcut.stringValue = row.shortcut ?? ""
        if row.isHeader {
            title.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            title.textColor = .secondaryLabelColor
            icon.image = nil
        } else {
            title.font = .systemFont(ofSize: 13)
            title.textColor = row.isEnabled ? .labelColor : .tertiaryLabelColor
            icon.image = row.symbolName.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }
        }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            let emphasized = backgroundStyle == .emphasized
            title.textColor = emphasized ? .alternateSelectedControlTextColor : (title.textColor ?? .labelColor)
            shortcut.textColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
            icon.contentTintColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
        }
    }
}

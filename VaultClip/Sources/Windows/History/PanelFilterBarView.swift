//
// PanelFilterBarView — type chips + app filter popup for the history panel (U13/U14).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class PanelFilterBarView: NSView {
    var onTypeChange: ((TypeFilter) -> Void)?
    var onAppChange: ((String?) -> Void)?

    private let typeScroll = NSScrollView(frame: .zero)
    private let typeStack = NSStackView(frame: .zero)
    private let appButton = NSPopUpButton(frame: .zero, pullsDown: true)
    private var typeButtons: [TypeFilter: NSButton] = [:]
    private var current = FilterState()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    func apply(_ state: FilterState) {
        current = state
        for (type, button) in typeButtons {
            button.state = type == state.type ? .on : .off
        }
        updateAppTitle()
    }

    func reloadApps(from items: [(bundleId: String?, displayName: String)], selectedQuery: String?) {
        let agg = AppFilterAggregator.aggregate(items: items)
        appButton.removeAllItems()
        appButton.addItem(withTitle: L10n.filterAllApps)
        appButton.menu?.items.first?.representedObject = Optional<String>.none as Any
        for entry in agg {
            let title = "\(entry.displayName) (\(entry.count))"
            appButton.addItem(withTitle: title)
            let item = appButton.lastItem
            item?.image = SourceAppIconProvider.icon(forBundleId: entry.bundleId)
            item?.image?.size = NSSize(width: 16, height: 16)
            item?.representedObject = entry.bundleId ?? "unknown"
        }
        if let query = selectedQuery, !query.isEmpty {
            if let match = appButton.itemArray.first(where: {
                ($0.representedObject as? String)?.localizedCaseInsensitiveContains(query) == true
                    || $0.title.localizedCaseInsensitiveContains(query)
            }) {
                appButton.select(match)
            }
        } else {
            appButton.selectItem(at: 0)
        }
        updateAppTitle()
    }

    private func build() {
        typeStack.orientation = .horizontal
        typeStack.spacing = 6
        typeStack.alignment = .centerY
        typeStack.translatesAutoresizingMaskIntoConstraints = false

        let chips: [(TypeFilter, String)] = [
            (.all, L10n.filterTypeAll),
            (.text, L10n.filterTypeText),
            (.link, L10n.filterTypeLinks),
            (.image, L10n.filterTypeImages),
            (.file, L10n.filterTypeFiles),
            (.color, L10n.filterTypeColors)
        ]
        for (type, title) in chips {
            let button = NSButton(title: title, target: self, action: #selector(typeTapped(_:)))
            button.bezelStyle = .rounded
            button.setButtonType(.onOff)
            button.tag = chips.firstIndex(where: { $0.0 == type }) ?? 0
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            typeButtons[type] = button
            typeStack.addArrangedSubview(button)
        }

        typeScroll.translatesAutoresizingMaskIntoConstraints = false
        typeScroll.drawsBackground = false
        typeScroll.hasHorizontalScroller = true
        typeScroll.hasVerticalScroller = false
        typeScroll.horizontalScrollElasticity = .allowed
        typeScroll.documentView = typeStack
        typeScroll.heightAnchor.constraint(equalToConstant: 28).isActive = true

        appButton.translatesAutoresizingMaskIntoConstraints = false
        appButton.target = self
        appButton.action = #selector(appPicked(_:))
        appButton.addItem(withTitle: L10n.filterAllApps)

        let row = NSStackView(views: [typeScroll, appButton])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            appButton.widthAnchor.constraint(lessThanOrEqualToConstant: 180),
            typeScroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        typeScroll.setContentHuggingPriority(.defaultLow, for: .horizontal)
        appButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        apply(FilterState())
    }

    private func updateAppTitle() {
        if let query = current.appQuery, !query.isEmpty {
            appButton.item(at: 0)?.title = query
        } else {
            appButton.item(at: 0)?.title = L10n.filterAllApps
        }
    }

    @objc private func typeTapped(_ sender: NSButton) {
        let order: [TypeFilter] = [.all, .text, .link, .image, .file, .color]
        guard sender.tag >= 0, sender.tag < order.count else { return }
        onTypeChange?(order[sender.tag])
    }

    @objc private func appPicked(_ sender: NSPopUpButton) {
        guard let item = sender.selectedItem else { return }
        let value = item.representedObject as? String
        if value == nil || sender.indexOfSelectedItem == 0 {
            onAppChange?(nil)
        } else if value == "unknown" {
            onAppChange?("unknown")
        } else {
            onAppChange?(item.title.components(separatedBy: " (").first ?? value)
        }
    }
}

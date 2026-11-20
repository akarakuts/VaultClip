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

    private let typeControl = NSSegmentedControl()
    private let appButton = NSPopUpButton(frame: .zero, pullsDown: false)
    private static let order: [TypeFilter] = [.all, .text, .link, .image, .file, .color]
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
        typeControl.selectedSegment = Self.order.firstIndex(of: state.type) ?? 0
        updateAppTitle()
    }

    /// ⌥⌘A — open the app popup menu (not just focus the bar).
    func openAppMenu() {
        window?.makeFirstResponder(appButton)
        appButton.performClick(nil)
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
        // «Все» as text, the rest as SF Symbols with tooltips so six types fit a 460pt edge panel.
        let titles: [(TypeFilter, String, String?)] = [
            (.all, L10n.filterTypeAll, nil),
            (.text, L10n.filterTypeText, "text.alignleft"),
            (.link, L10n.filterTypeLinks, "link"),
            (.image, L10n.filterTypeImages, "photo"),
            (.file, L10n.filterTypeFiles, "doc"),
            (.color, L10n.filterTypeColors, "paintpalette")
        ]
        typeControl.segmentCount = titles.count
        typeControl.trackingMode = .selectOne
        typeControl.segmentStyle = .rounded
        typeControl.controlSize = .small
        typeControl.target = self
        typeControl.action = #selector(typeChanged(_:))
        for (index, entry) in titles.enumerated() {
            if let symbol = entry.2 {
                typeControl.setImage(NSImage(systemSymbolName: symbol, accessibilityDescription: entry.1), forSegment: index)
                typeControl.setWidth(30, forSegment: index)
            } else {
                typeControl.setLabel(entry.1, forSegment: index)
            }
            typeControl.setToolTip(entry.1, forSegment: index)
        }
        typeControl.translatesAutoresizingMaskIntoConstraints = false
        typeControl.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        appButton.translatesAutoresizingMaskIntoConstraints = false
        appButton.controlSize = .small
        appButton.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        appButton.target = self
        appButton.action = #selector(appPicked(_:))
        appButton.addItem(withTitle: L10n.filterAllApps)
        appButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        appButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(typeControl)
        addSubview(appButton)
        NSLayoutConstraint.activate([
            typeControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            typeControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            // Flexible gap: a rigid chain capped the whole panel at ~420pt wide (top/bottom positions).
            appButton.leadingAnchor.constraint(greaterThanOrEqualTo: typeControl.trailingAnchor, constant: 8),
            appButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            appButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            appButton.widthAnchor.constraint(lessThanOrEqualToConstant: 220)
        ])
        let fill = appButton.leadingAnchor.constraint(equalTo: typeControl.trailingAnchor, constant: 8)
        fill.priority = .dragThatCannotResizeWindow
        fill.isActive = true
        apply(FilterState())
    }

    private func updateAppTitle() {
        if let query = current.appQuery, !query.isEmpty {
            appButton.item(at: 0)?.title = query
        } else {
            appButton.item(at: 0)?.title = L10n.filterAllApps
        }
    }

    @objc private func typeChanged(_ sender: NSSegmentedControl) {
        let index = sender.selectedSegment
        guard index >= 0, index < Self.order.count else { return }
        onTypeChange?(Self.order[index])
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

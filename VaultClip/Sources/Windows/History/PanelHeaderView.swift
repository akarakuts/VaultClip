//
// PanelHeaderView — search field, tab segments, filter/preview/overflow buttons (U08).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class PanelHeaderView: NSView {
    let searchField = NSSearchField(frame: .zero)
    let tabs = NSSegmentedControl(labels: [
        L10n.tabHistory, L10n.tabFavorites, L10n.tabPasswords
    ], trackingMode: .selectOne, target: nil, action: nil)
    let filterButton = NSButton(frame: .zero)
    let previewButton = NSButton(frame: .zero)
    let moreButton = NSButton(frame: .zero)
    let filterBar = NSView(frame: .zero)

    var onTabChange: ((HistoryListMode) -> Void)?
    var onFilterToggle: (() -> Void)?
    var onPreviewToggle: (() -> Void)?
    var onMoreMenu: ((NSButton) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    func apply(_ model: PanelHeaderModel) {
        searchField.placeholderString = model.searchPlaceholder
        searchField.toolTip = model.searchTooltip
        filterBar.isHidden = !model.showsFilterBar
        previewButton.isHidden = !model.showsPreviewButton
    }

    func selectTab(_ mode: HistoryListMode) {
        tabs.selectedSegment = mode.rawValue
    }

    private func build() {
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false

        tabs.translatesAutoresizingMaskIntoConstraints = false
        tabs.segmentStyle = .rounded
        tabs.target = self
        tabs.action = #selector(tabChanged)

        configureIconButton(filterButton, symbol: "line.3.horizontal.decrease.circle", action: #selector(filterTapped))
        configureIconButton(previewButton, symbol: "sidebar.right", action: #selector(previewTapped))
        configureIconButton(moreButton, symbol: "ellipsis.circle", action: #selector(moreTapped))

        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.setContentHuggingPriority(.defaultLow, for: .vertical)

        let topRow = NSStackView(views: [searchField, filterButton, previewButton, moreButton])
        topRow.orientation = .horizontal
        topRow.spacing = PanelTheme.Spacing.controlGap
        topRow.alignment = .centerY
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [topRow, tabs, filterBar])
        stack.orientation = .vertical
        stack.spacing = PanelTheme.Spacing.sm
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            topRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            searchField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            tabs.widthAnchor.constraint(equalTo: stack.widthAnchor),
            filterBar.heightAnchor.constraint(equalToConstant: 28),
            filterBar.widthAnchor.constraint(equalTo: stack.widthAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum),
            filterButton.heightAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum),
            previewButton.widthAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum),
            previewButton.heightAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum),
            moreButton.widthAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum),
            moreButton.heightAnchor.constraint(equalToConstant: PanelTheme.HitTarget.minimum)
        ])
    }

    private func configureIconButton(_ button: NSButton, symbol: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .inline
        button.isBordered = false
        let label: String
        switch action {
        case #selector(filterTapped): label = L10n.a11yHeaderFilter
        case #selector(previewTapped): label = L10n.a11yHeaderPreview
        default: label = L10n.a11yHeaderMore
        }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.imagePosition = .imageOnly
        button.toolTip = label
        button.setAccessibilityLabel(label)
        button.target = self
        button.action = action
    }

    @objc private func tabChanged() {
        guard let mode = HistoryListMode(rawValue: tabs.selectedSegment) else { return }
        onTabChange?(mode)
    }

    @objc private func filterTapped() { onFilterToggle?() }
    @objc private func previewTapped() { onPreviewToggle?() }
    @objc private func moreTapped() { onMoreMenu?(moreButton) }
}

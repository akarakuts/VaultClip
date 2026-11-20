//
// HistoryViewController+Layout — programmatic panel column, preview split, footer, toasts (U08/U09/U21).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

extension HistoryViewController {

    // ── Layout ──

    /// Storyboard constraints fought the programmatic filter/preview/footer rows; own the column here.
    func installProgrammaticPanelLayout() {
        guard let scrollView = historyListView.enclosingScrollView else { return }
        footerSeparator.boxType = .separator
        footerHintsLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        footerHintsLabel.textColor = .tertiaryLabelColor
        footerHintsLabel.alignment = .right
        footerHintsLabel.lineBreakMode = .byTruncatingHead
        footerHintsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        itemCountLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        itemCountLabel.textColor = .secondaryLabelColor
        itemCountLabel.alignment = .left
        itemCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        for sub in [footerSeparator, footerHintsLabel] as [NSView] where sub.superview == nil {
            view.addSubview(sub)
        }

        let managed: [NSView] = [
            searchBar, itemGroupScrollView, itemCountLabel, scrollView,
            filterBar, embeddedPreview, footerHintsLabel, footerSeparator
        ]
        let storyboardLabels = view.subviews.compactMap { $0 as? NSTextField }
            .filter { field in !managed.contains(where: { $0 === field }) }
        let ids = Set((managed + storyboardLabels).map { ObjectIdentifier($0) })
        func touches(_ item: AnyObject?) -> Bool {
            guard let item else { return false }
            return ids.contains(ObjectIdentifier(item))
        }
        NSLayoutConstraint.deactivate(view.constraints.filter { touches($0.firstItem) || touches($0.secondItem) })
        storyboardLabels.forEach { $0.isHidden = true }
        managed.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let inset = PanelChrome.Metrics.panelContentInset
        let filterHeight = filterBar.heightAnchor.constraint(equalToConstant: 26)
        filterBarHeightConstraint = filterHeight
        let listBottom = scrollView.bottomAnchor.constraint(equalTo: footerSeparator.topAnchor, constant: -4)
        let listTrailing = scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(inset - 4))
        listBottomToFooter = listBottom
        listTrailingToView = listTrailing

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: PanelChrome.Metrics.headerTopInset),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),

            itemGroupScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            itemGroupScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            itemGroupScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),

            filterBar.topAnchor.constraint(equalTo: itemGroupScrollView.bottomAnchor, constant: 6),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            filterBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            filterHeight,

            scrollView.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset - 4),
            listTrailing,
            listBottom,

            footerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerSeparator.heightAnchor.constraint(equalToConstant: 1),
            footerSeparator.bottomAnchor.constraint(equalTo: itemCountLabel.topAnchor, constant: -5),

            itemCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            itemCountLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),

            footerHintsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            footerHintsLabel.centerYAnchor.constraint(equalTo: itemCountLabel.centerYAnchor),
            footerHintsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: itemCountLabel.trailingAnchor, constant: 12)
        ])
        updateFilterBarVisibility()
        applyPreviewAxis()
    }

    func updateFilterBarVisibility() {
        let show = appSettings.showsFilterBarPreference && listMode.value != .passwords
        filterBar.isHidden = !show
        filterBarHeightConstraint?.constant = show ? 26 : 0
    }

    // ── Preview split (U21) ──

    func installEmbeddedPreview() {
        isPreviewShowing = appSettings.previewVisible
        embeddedPreview.translatesAutoresizingMaskIntoConstraints = false
        embeddedPreview.isHidden = true
        view.addSubview(embeddedPreview)
        embeddedPreview.onPaste = { [weak self] in
            guard let self else { return }
            if self.embeddedPreview.isEditing {
                self.pasteEditedPreviewText()
            } else {
                self.pasteSelected()
            }
        }
        embeddedPreview.onCopy = { [weak self] in self?.copySelected() }
        embeddedPreview.onEdit = { [weak self] in self?.beginEditBeforePaste() }
        embeddedPreview.onOpen = { [weak self] in self?.openSelectedLinkOrFile() }
        selected.subscribe(onNext: { [weak self] _ in
            self?.scheduleEmbeddedPreviewUpdate()
        }).disposed(by: disposeBag)
    }

    func syncEmbeddedPreviewVisibility() {
        isPreviewShowing = appSettings.previewVisible
        applyPreviewAxis()
    }

    func togglePreview() {
        isPreviewShowing.toggle()
        let visible = isPreviewShowing
        SettingsPersistence.apply { $0.previewVisible = visible }
        applyPreviewAxis()
        appState.previewHistoryItem.accept(nil)
    }

    /// Picks none / beside / below from PreviewLayout and swaps the split constraints.
    func applyPreviewAxis() {
        guard let scrollView = historyListView.enclosingScrollView,
              let listBottom = listBottomToFooter,
              let listTrailing = listTrailingToView else { return }
        let width = view.bounds.width > 0 ? view.bounds.width : 480
        let axis = PreviewLayout.layout(PreviewLayoutInput(
            panelWidth: width,
            panelHeight: view.bounds.height,
            position: appState.panelPosition.value,
            previewVisible: isPreviewShowing,
            listFraction: nil
        ))?.axis
        let wasHidden = embeddedPreview.isHidden
        guard axis != currentPreviewAxis || previewConstraints.isEmpty && axis != nil else {
            embeddedPreview.isHidden = axis == nil
            return
        }
        currentPreviewAxis = axis
        NSLayoutConstraint.deactivate(previewConstraints)
        previewConstraints.removeAll()
        let inset = PanelChrome.Metrics.panelContentInset
        switch axis {
        case .none:
            listBottom.isActive = true
            listTrailing.isActive = true
            embeddedPreview.isHidden = true
        case .horizontal?:
            listBottom.isActive = true
            listTrailing.isActive = false
            let preferred = embeddedPreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
            preferred.priority = .defaultHigh
            previewConstraints = [
                scrollView.trailingAnchor.constraint(equalTo: embeddedPreview.leadingAnchor, constant: -6),
                embeddedPreview.topAnchor.constraint(equalTo: scrollView.topAnchor),
                embeddedPreview.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                embeddedPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
                embeddedPreview.widthAnchor.constraint(greaterThanOrEqualToConstant: PreviewLayout.minPreviewWidth),
                preferred
            ]
            embeddedPreview.isHidden = false
        case .vertical?:
            listBottom.isActive = false
            listTrailing.isActive = true
            let preferred = embeddedPreview.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.36)
            preferred.priority = .defaultHigh
            previewConstraints = [
                scrollView.bottomAnchor.constraint(equalTo: embeddedPreview.topAnchor, constant: -6),
                embeddedPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
                embeddedPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
                embeddedPreview.bottomAnchor.constraint(equalTo: footerSeparator.topAnchor, constant: -6),
                embeddedPreview.heightAnchor.constraint(greaterThanOrEqualToConstant: PreviewLayout.minPreviewHeight),
                preferred
            ]
            embeddedPreview.isHidden = false
        }
        NSLayoutConstraint.activate(previewConstraints)
        if wasHidden, !embeddedPreview.isHidden {
            refreshEmbeddedPreview()
        }
        historyListView.syncColumnWidthToScrollView()
    }

    func scheduleEmbeddedPreviewUpdate() {
        guard isPreviewShowing, !embeddedPreview.isHidden else { return }
        previewDebouncer.schedule { [weak self] _ in
            DispatchQueue.main.async { self?.refreshEmbeddedPreview() }
        }
    }

    func refreshEmbeddedPreview() {
        guard !embeddedPreview.isHidden else { return }
        guard let item = selectedHistoryItem else {
            embeddedPreview.showEmpty()
            return
        }
        embeddedPreview.show(previewContent(for: item))
    }

    private func previewContent(for item: HistoryItem) -> EmbeddedPreviewContent {
        let summary = HistoryItemSummaryBuilder.shared.summary(for: item)
        let mono = appSettings.usesMonospacedContentFont
        switch summary.kind {
        case .password:
            return .password(comment: item.passwordComment, login: item.passwordLogin, url: item.passwordURL)
        case .image:
            if let image = item.getImage() {
                let size = summary.imagePixelSize.map { " · \(Int($0.width))×\(Int($0.height))" } ?? ""
                return .image(image, caption: "\(summary.imageFormat ?? "PNG")\(size)")
            }
        case .color:
            if let color = item.getColor() {
                return .color(color, caption: summary.colorHex ?? "")
            }
        case .file:
            if let url = item.getFileUrl() {
                return .files([url])
            }
        case .link:
            let url = item.getUrl()?.absoluteString ?? summary.title
            return .link(host: summary.linkHost ?? url, url: url)
        default:
            break
        }
        let text = item.getPlainString() ?? item.getPdfDisplayString() ?? ""
        return .text(text, monospaced: mono)
    }

    // ── Footer (U09) ──

    func refreshFooterHints() {
        let context: PanelHintContext = selectionModel.isMulti
            ? .multiSelect(count: selectionModel.count)
            : (embeddedPreview.isEditing ? .editor : .list)
        let input = PanelStatusBarInput(
            totalCount: historyPanel.items.count,
            visibleCount: historyPanel.items.count,
            isSearch: results.value.isSearchResult,
            selectedCount: selectionModel.count,
            isLoading: !appState.isHistoryLoaded,
            hintContext: context,
            availableWidth: max(0, view.bounds.width - itemCountLabel.intrinsicContentSize.width - 48),
            showKeyHints: appSettings.showKeyHints,
            locale: .current
        )
        footerHintsLabel.stringValue = PanelStatusBarPresenter.hints(for: input).joined(separator: "  ·  ")
    }

    // ── Toasts (U09/U18) ──

    func installToast() {
        view.addSubview(toastView)
        // Anchor to the list, not the footer, so a bottom preview's buttons stay clickable.
        guard let scrollView = historyListView.enclosingScrollView else { return }
        NSLayoutConstraint.activate([
            toastView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            toastView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32)
        ])
    }

    func showToast(_ message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        let duration = actionTitle == nil
            ? PanelStatusBarPresenter.toastNormalSeconds
            : PanelStatusBarPresenter.toastUndoSeconds
        toastView.show(message: message, actionTitle: actionTitle, duration: duration, action: action)
    }

    var selectedHistoryItem: HistoryItem? {
        guard let row = historyListView.selected, row >= 0, row < historyPanel.items.count else { return nil }
        return historyPanel.items[row]
    }
}

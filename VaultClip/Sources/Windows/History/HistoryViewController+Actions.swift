//
// HistoryViewController+Actions — item commands from keys, palette, row buttons and context menu (U15/U17/U22–U24).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Quartz

extension HistoryViewController {

    /// Selection in list order; falls back to the focused row.
    var selectedHistoryItems: [HistoryItem] {
        let rows = historyListView.selectedRowIndexes.filter { $0 < historyPanel.items.count }
        if !rows.isEmpty { return rows.map { historyPanel.items[$0] } }
        return selectedHistoryItem.map { [$0] } ?? []
    }

    func copySelected() {
        let items = selectedHistoryItems
        guard !items.isEmpty else { return }
        if items.count == 1 {
            historyPanel.copyToClipboard(item: items[0])
            showToast(L10n.toastCopied)
            return
        }
        let separator = MultiPasteSeparator(rawValue: appSettings.multiPasteSeparator) ?? .newline
        let result = MultiPasteComposer.compose(
            items: items.map { MultiPasteComposer.Item(kind: itemKind(for: $0), text: $0.getPlainString(), isPassword: $0.isPassword) },
            separator: separator
        )
        if case .joinedText(let text) = result.payload {
            historyPanel.copyText(text)
            showToast(L10n.toastCopied)
        }
    }

    func toggleFavoriteSelected() {
        let items = selectedHistoryItems.filter { !$0.isPassword }
        guard !items.isEmpty else { return }
        // Batch rule: if any item is not a favorite, favorite them all.
        let target = items.contains { !$0.isFavorite }
        for item in items where item.isFavorite != target {
            _ = historyPanel.toggleFavorite(item: item)
        }
    }

    func openSelectedLinkOrFile() {
        guard let item = selectedHistoryItem else { return }
        if item.isPassword {
            historyPanel.openPasswordURL(item: item)
            return
        }
        if let url = item.getFileUrl() {
            NSWorkspace.shared.open(url)
        } else if let url = item.getUrl() ?? item.getPlainString().flatMap(URL.init(string:)),
                  let scheme = url.scheme?.lowercased(), ["http", "https", "mailto", "ftp"].contains(scheme) {
            NSWorkspace.shared.open(url)
        } else if let url = item.makeQuickLookPreviewURL() {
            NSWorkspace.shared.open(url)
        } else {
            return
        }
        close(reason: .userAction)
    }

    func revealSelectedInFinder() {
        guard let url = selectedHistoryItem?.getFileUrl() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func toggleQuickLook() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if QLPreviewPanel.sharedPreviewPanelExists(), panel.isVisible {
            panel.orderOut(nil)
            return
        }
        guard let item = selectedHistoryItem, item.hasQuickLookPreview else {
            // Images/text have no file to hand Quick Look — show the in-panel preview instead.
            if !isPreviewShowing { togglePreview() }
            return
        }
        quickLookURL = item.makeQuickLookPreviewURL()
        panel.makeKeyAndOrderFront(nil)
    }

    func beginEditBeforePaste() {
        guard let item = selectedHistoryItem, !item.isPassword else { return }
        let kind = itemKind(for: item)
        guard EditBeforePaste.availability(for: kind) != .unavailable else { return }
        if !isPreviewShowing { togglePreview() }
        refreshEmbeddedPreview()
        embeddedPreview.beginEditing()
        refreshFooterHints()
    }

    func pasteEditedPreviewText() {
        guard embeddedPreview.isEditing, let item = selectedHistoryItem else {
            pasteSelected()
            return
        }
        let text = embeddedPreview.editedText
        embeddedPreview.endEditing()
        close(reason: .paste)
        historyPanel.multiPasteJoined(text, items: [item])
    }

    func changeTextSize(by delta: Int) {
        let all = TextSizePreference.allCases
        let current = appSettings.panelTextSize
        guard let index = all.firstIndex(of: current) else { return }
        let next = all[min(max(0, index + delta), all.count - 1)]
        guard next != current else { return }
        SettingsPersistence.apply { $0.panelTextSize = next }
        historyListView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<historyListView.numberOfRows))
        historyListView.reloadData(historyPanel.items, isRichText: isRichText, listMode: listMode.value)
        if let row = selected.value { historyListView.selectItem(row) }
    }

    func movePage(direction: Int) {
        let count = historyPanel.items.count
        guard count > 0 else { return }
        let rowHeight = PanelTheme.rowHeight(for: appSettings.panelTextSize)
        let viewport = historyListView.enclosingScrollView?.contentView.bounds.height ?? rowHeight
        let page = PanelNavigation.pageSize(visibleRowHeight: rowHeight, viewportHeight: viewport)
        let target = PanelNavigation.indexAfterPage(
            current: selected.value ?? 0,
            direction: direction,
            pageSize: page,
            count: count
        )
        selected.accept(target)
    }

    func filterToAppOfItem(at row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        let item = historyPanel.items[row]
        filterState.appQuery = item.sourceBundleId.map { SourceAppDisplayName.name(forBundleId: $0) } ?? "unknown"
        filterBar.apply(filterState)
        scheduleSearch()
    }

    func performRowAction(_ action: RowActionButtonID, at row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        if !historyListView.selectedRowIndexes.contains(row) {
            historyListView.selectItem(row)
            selected.accept(row)
        }
        let item = historyPanel.items[row]
        switch action {
        case .paste: paste(selected: row)
        case .pastePlainText: pasteSelectedPlainText()
        case .toggleFavorite: _ = historyPanel.toggleFavorite(item: item)
        case .more: performPanelCommand(.commandPalette)
        case .copyLogin: historyPanel.copyLogin(item: item)
        case .copyPassword: historyPanel.copyPassword(item: item)
        }
    }

    func performContextCommand(_ command: PanelCommandID, at row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        if !historyListView.selectedRowIndexes.contains(row) {
            historyListView.selectItem(row)
        }
        selected.accept(historyListView.selected ?? row)
        performPanelCommand(command)
    }
}

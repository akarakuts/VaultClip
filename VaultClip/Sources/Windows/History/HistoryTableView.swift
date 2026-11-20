//
//  HistoryTableView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryTableView: NSTableView {
    
    var historyListItems = [HistoryItem]()
    
    var historyDelegate: HistoryTableViewDelegate?
    private var draggingContainsPassword = false
    private(set) var isApplyingProgrammaticSelection = false
    
    var cellWidth: CGFloat {
        return tableColumns[0].width
    }
    
    var cellHeightsCache = CellHeightsCache()
    
    var isRichText: Bool = true
    
    var listMode: HistoryListMode = .history

    /// Date headers between items (U12); rows ≠ item indexes while this is on.
    var groupsByDate = false
    enum DisplayRow: Equatable {
        case header(String)
        case item(Int)
    }
    private(set) var displayRows: [DisplayRow] = []
    private var rowForItem: [Int] = []

    /// Rebuilds header placement; buckets use lastUsedAt like retention.
    func rebuildDisplayRows(now: Date = Date()) {
        var rows: [DisplayRow] = []
        var map: [Int] = []
        var lastBucket: DateGroupBucket?
        let calendar = Calendar.current
        for (index, item) in historyListItems.enumerated() {
            if groupsByDate {
                let bucket = DateGrouping.bucket(for: item.lastUsedAt, now: now, calendar: calendar)
                if bucket != lastBucket {
                    rows.append(.header(DateGrouping.title(for: bucket, now: now, calendar: calendar, locale: .current)))
                    lastBucket = bucket
                }
            }
            map.append(rows.count)
            rows.append(.item(index))
        }
        displayRows = rows
        rowForItem = map
    }

    // Ungrouped lists map 1:1 (also during incremental insert/remove, before the rebuild).
    func itemIndex(forRow row: Int) -> Int? {
        guard groupsByDate else { return row >= 0 && row < historyListItems.count ? row : nil }
        guard displayRows.indices.contains(row), case .item(let index) = displayRows[row] else { return nil }
        return index
    }

    func row(forItemIndex index: Int) -> Int? {
        guard groupsByDate else { return index >= 0 && index < historyListItems.count ? index : nil }
        return rowForItem.indices.contains(index) ? rowForItem[index] : nil
    }

    /// Selected item indexes in list order (headers excluded).
    var selectedItemIndexes: IndexSet {
        IndexSet(selectedRowIndexes.compactMap { itemIndex(forRow: $0) })
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        selectionHighlightStyle = .regular
        allowsMultipleSelection = true
        columnAutoresizingStyle = .noColumnAutoresizing
        applyPlainListAppearance()
        setAccessibilityIdentifier(Accessibility.identifiers.historyTableView)
        
        delegate = self
        dataSource = self
        target = self
        doubleAction = #selector(rowDoubleClicked(_:))
        
        registerForDraggedTypes([HistoryItem.historyItemIdType])
    }
    
    /// Fixed-height rows; `.plain` so the single column never overflows the clip view
    /// (`.inset` adds hidden side margins that cropped the ⌘N badge). Rounded selection lives in HistoryTableRowView.
    func applyPlainListAppearance() {
        style = .plain
        rowSizeStyle = .custom
        intercellSpacing = .zero
        usesAutomaticRowHeights = false
        guard let scrollView = enclosingScrollView else { return }
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.contentInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyPlainListAppearance()
    }
    
    /// Delegates width enforcement to the clip view, the single owner of the visible viewport width.
    func syncColumnWidthToScrollView() {
        guard let scrollView = enclosingScrollView,
              let column = tableColumns.first else { return }
        let clipView = scrollView.contentView
        
        applyPlainListAppearance()
        
        let width = floor(clipView.bounds.width)
        guard width > 0 else { return }
        
        if let listClipView = clipView as? HistoryListClipView {
            listClipView.enforceDocumentWidth()
        } else {
            if abs(column.width - width) > 0.5 {
                column.width = width
            }
            if abs(clipView.bounds.origin.x) > 0.5 {
                clipView.setBoundsOrigin(NSPoint(x: 0, y: clipView.bounds.origin.y))
            }
        }
    }
    
    func remeasureVisibleRows() {
        syncColumnWidthToScrollView()
        let rows = numberOfRows
        guard rows > 0 else { return }
        noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<rows))
        redisplayVisible(historyListItems: historyListItems)
    }
    
    /// First selected item index (not table row).
    var selected: Int? {
        selectedItemIndexes.first
    }
    
    func selectItem(_ i: Int) {
        guard let row = row(forItemIndex: i), row < numberOfRows else { return }
        performProgrammaticSelection {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        // Keep the group header visible above the first item.
        scrollRowToVisible(i == 0 ? 0 : row)
    }
    
    func deselectItem(_ i: Int) {
        guard let row = row(forItemIndex: i) else { return }
        performProgrammaticSelection { deselectRow(row) }
    }

    /// Programmatic changes must not echo back through the delegate (feedback loop with `selected`).
    func performProgrammaticSelection(_ change: () -> Void) {
        let wasProgrammatic = isApplyingProgrammaticSelection
        isApplyingProgrammaticSelection = true
        change()
        isApplyingProgrammaticSelection = wasProgrammatic
    }
    
    func reloadItem(_ i: Int) {
        guard let row = row(forItemIndex: i), row < numberOfRows else { return }
        reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        syncColumnWidthToScrollView()
    }
    
    func redisplayVisible(historyListItems: [HistoryItem]) {
        let range = rows(in: visibleRect)
        guard range.length > 0 else { return }
        let upper = min(range.location + range.length, numberOfRows)
        guard range.location < upper else { return }
        reloadData(forRowIndexes: IndexSet(integersIn: range.location..<upper), columnIndexes: IndexSet(integer: 0))
    }
    
    func reloadData(_ data: [HistoryItem], isRichText: Bool, listMode: HistoryListMode) {
        historyListItems = data
        self.isRichText = isRichText
        self.listMode = listMode
        rebuildDisplayRows()
        applyPlainListAppearance()
        performProgrammaticSelection { super.reloadData() }
        syncColumnWidthToScrollView()
        remeasureVisibleRows()
    }

    enum RowMutation: Equatable {
        case insertTop
        case delete(UUID)
        case move(UUID)
        case reload
    }

    /// Incremental row updates without wiping CellHeightsCache (T24).
    func applyItemsIncrementally(
        _ data: [HistoryItem],
        isRichText: Bool,
        listMode: HistoryListMode,
        mutation: RowMutation
    ) {
        let previous = historyListItems
        self.isRichText = isRichText
        self.listMode = listMode
        applyPlainListAppearance()
        let wasProgrammatic = isApplyingProgrammaticSelection
        isApplyingProgrammaticSelection = true
        defer { isApplyingProgrammaticSelection = wasProgrammatic }
        if groupsByDate {
            historyListItems = data
            rebuildDisplayRows()
            super.reloadData()
            syncColumnWidthToScrollView()
            return
        }
        defer { rebuildDisplayRows() }

        switch mutation {
        case .insertTop where data.count == previous.count + 1:
            historyListItems = data
            beginUpdates()
            insertRows(at: IndexSet(integer: 0), withAnimation: [])
            endUpdates()
        case .delete(let id):
            if let row = previous.firstIndex(where: { $0.fsId == id }), data.count == previous.count - 1 {
                historyListItems = data
                beginUpdates()
                removeRows(at: IndexSet(integer: row), withAnimation: [])
                endUpdates()
                cellHeightsCache.removeCellHeight(forId: id)
            } else {
                historyListItems = data
                super.reloadData()
            }
        case .move(let id):
            if let from = previous.firstIndex(where: { $0.fsId == id }),
               let to = data.firstIndex(where: { $0.fsId == id }),
               from != to,
               data.count == previous.count {
                historyListItems = data
                beginUpdates()
                moveRow(at: from, to: to)
                endUpdates()
            } else {
                historyListItems = data
                super.reloadData()
            }
        default:
            historyListItems = data
            super.reloadData()
        }
        syncColumnWidthToScrollView()
        remeasureVisibleRows()
    }
}

extension HistoryTableView: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        groupsByDate ? displayRows.count : historyListItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if displayRows.indices.contains(row), case .header(let title) = displayRows[row] {
            return makeGroupHeader(title)
        }
        guard let itemRow = itemIndex(forRow: row) else { return nil }
        let isRowSelected = selectedRowIndexes.contains(row)
        let historyItem = historyListItems[itemRow]
        let row = itemRow
        let cell = tableView.makeView(withIdentifier: HistoryRowView.identifier, owner: nil) as? HistoryRowView
            ?? HistoryRowView(frame: .zero)
        let summary = HistoryItemSummaryBuilder.shared.summary(for: historyItem)
        let presentation = RowPresentationBuilder.presentation(
            id: historyItem.fsId,
            summary: summary,
            locale: .current,
            now: Date()
        )
        let shortcut: Int? = (1...9).contains(row + 1) ? row + 1 : (row == 9 ? 0 : nil)
        cell.apply(
            presentation: presentation,
            artwork: RowArtworkProvider.image(for: historyItem, kind: summary.kind),
            shortcutNumber: shortcut,
            textSize: SettingsPersistence.current().panelTextSize,
            isFavorite: historyItem.isFavorite,
            isPassword: historyItem.isPassword,
            tab: listMode
        )
        cell.setRowSelected(isRowSelected)
        let itemId = historyItem.fsId
        cell.onAction = { [weak self] action in
            guard let self, let current = self.historyListItems.firstIndex(where: { $0.fsId == itemId }) else { return }
            self.historyDelegate?.historyTableView(self, performRowAction: action, at: current)
        }
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView.makeView(withIdentifier: HistoryTableRowView.identifier, owner: nil) as? HistoryTableRowView
            ?? {
                let view = HistoryTableRowView()
                view.identifier = HistoryTableRowView.identifier
                return view
            }()
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        guard !isApplyingProgrammaticSelection else { return }
        historyDelegate?.historyTableView(self, selectedDidChange: selected)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isApplyingProgrammaticSelection else { return }
        historyDelegate?.historyTableView(self, selectedDidChange: selected)
    }

    /// Selects by **item** indexes (not table rows). Maps through headers when grouped by date.
    func selectItems(_ indexes: IndexSet) {
        let rows = IndexSet(indexes.compactMap { row(forItemIndex: $0) })
        performProgrammaticSelection {
            selectRowIndexes(rows, byExtendingSelection: false)
        }
        if let first = rows.first {
            scrollRowToVisible(first)
        }
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<numberOfRows))
        NSAnimationContext.endGrouping()
        redisplayVisible(historyListItems: historyListItems)
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard let index = itemIndex(forRow: row) else { return nil }
        return historyListItems[index]
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        guard groupsByDate, displayRows.indices.contains(row), case .header = displayRows[row] else { return false }
        return true
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        !self.tableView(tableView, isGroupRow: row)
    }

    private func makeGroupHeader(_ title: String) -> NSView {
        let id = NSUserInterfaceItemIdentifier("HistoryGroupHeader")
        let cell = (makeView(withIdentifier: id, owner: nil) as? NSTableCellView) ?? {
            let cell = NSTableCellView()
            cell.identifier = id
            let label = NSTextField(labelWithString: "")
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            label.textColor = .secondaryLabelColor
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            cell.textField = label
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: PanelTheme.Spacing.sm + 2),
                label.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -3)
            ])
            cell.setAccessibilityRole(.staticText)
            return cell
        }()
        cell.textField?.stringValue = title
        cell.setAccessibilityLabel(title)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        draggingContainsPassword = rowIndexes.contains { row in
            row < historyListItems.count && historyListItems[row].isPassword
        }
    }
    
    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if context == .outsideApplication {
            return draggingContainsPassword ? [] : .copy
        }
        return .move
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        // Reordering across date headers has no stable meaning.
        if groupsByDate { return [] }
        if dropOperation == .above {
            return .move
        }
        else {
            return []
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        var id: UUID?
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { dragItem, _, _ in

            guard let pasteboardItem = dragItem.item as? NSPasteboardItem else { return }
            if let idStr = pasteboardItem.string(forType: HistoryItem.historyItemIdType) {
                id = UUID(uuidString: idStr)
            }
        }
        
        guard let droppedId = id else {
            return false
        }
        
        guard let originalIndex = historyListItems.map({ $0.fsId }).firstIndex(of: droppedId) else {
            return false
        }
        
        let newIndex = originalIndex < row ? row - 1 : row
        
        if originalIndex == newIndex {
            return false
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            self.reloadData(forRowIndexes: IndexSet(integersIn: 0..<self.historyListItems.count), columnIndexes: IndexSet(integer: 0))
            if let delegate = self.historyDelegate {
                delegate.historyTableView(self, didMoveItem: originalIndex, to: newIndex)
            }
        })
        tableView.beginUpdates()
        
        let removed = historyListItems.remove(at: originalIndex)
        
        tableView.moveRow(at: originalIndex, to: newIndex)
        historyListItems.insert(removed, at: newIndex)
        
        tableView.endUpdates()
        CATransaction.commit()

        return true
    }
}

extension HistoryTableView: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if self.tableView(tableView, isGroupRow: row) { return 24 }
        return PanelTheme.rowHeight(for: SettingsPersistence.current().panelTextSize)
    }
    
}

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
    
    var selected: Int? {
        return self.selectedRowIndexes.first
    }
    
    func selectItem(_ i: Int) {
        guard i >= 0, i < numberOfRows else { return }
        performProgrammaticSelection {
            selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
        }
        scrollRowToVisible(i)
    }
    
    func deselectItem(_ i: Int) {
        performProgrammaticSelection { deselectRow(i) }
    }

    /// Programmatic changes must not echo back through the delegate (feedback loop with `selected`).
    func performProgrammaticSelection(_ change: () -> Void) {
        let wasProgrammatic = isApplyingProgrammaticSelection
        isApplyingProgrammaticSelection = true
        change()
        isApplyingProgrammaticSelection = wasProgrammatic
    }
    
    func reloadItem(_ i: Int) {
        reloadData(forRowIndexes: IndexSet(arrayLiteral: i), columnIndexes: IndexSet(arrayLiteral: 0))
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
        return historyListItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let historyItem = historyListItems[row]
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

    func selectItems(_ indexes: IndexSet) {
        performProgrammaticSelection {
            selectRowIndexes(indexes, byExtendingSelection: false)
        }
        if let first = indexes.first {
            scrollRowToVisible(first)
        }
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<historyListItems.count))
        NSAnimationContext.endGrouping()
        redisplayVisible(historyListItems: historyListItems)
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return historyListItems[row]
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
        PanelTheme.rowHeight(for: SettingsPersistence.current().panelTextSize)
    }
    
}

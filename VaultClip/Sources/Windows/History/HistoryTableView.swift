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
        selectionHighlightStyle = .none
        allowsMultipleSelection = false
        columnAutoresizingStyle = .noColumnAutoresizing
        applyPlainListAppearance()
        setAccessibilityIdentifier(Accessibility.identifiers.historyTableView)
        
        delegate = self
        dataSource = self
        
        registerForDraggedTypes([HistoryItem.historyItemIdType])
    }
    
    /// `.automatic` resolves to `.inset` in borderless scroll views (~10pt side padding on Big Sur+).
    func applyPlainListAppearance() {
        if #available(macOS 11.0, *) {
            style = .plain
        }
        rowSizeStyle = .custom
        intercellSpacing = NSSize(
            width: 0,
            height: HistoryListTheme.metrics.rowVerticalSpacing
        )
        guard let scrollView = enclosingScrollView else { return }
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        if #available(macOS 11.0, *) {
            scrollView.scrollerStyle = .overlay
            scrollView.contentInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        }
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
        let items = IndexSet(integer: i)
        selectRowIndexes(items, byExtendingSelection: false)
        scrollRowToVisible(i)
    }
    
    func deselectItem(_ i: Int) {
        deselectRow(i)
    }
    
    func reloadItem(_ i: Int) {
        reloadData(forRowIndexes: IndexSet(arrayLiteral: i), columnIndexes: IndexSet(arrayLiteral: 0))
        syncColumnWidthToScrollView()
    }
    
    func redisplayVisible(historyListItems: [HistoryItem]) {
        let vis = visibleRect
        let range = rows(in: vis)
        for row in range.location..<range.location+range.length {
            guard row < historyListItems.count,
                  let cell = view(atColumn: 0, row: row, makeIfNecessary: false) as? HistoryListItem else { continue }
            cell.setupCell(withHistoryTableView: self, forHistoryItem: historyListItems[row], at: row)
        }
    }
    
    func reloadData(_ data: [HistoryItem], isRichText: Bool, listMode: HistoryListMode) {
        historyListItems = data
        self.isRichText = isRichText
        self.listMode = listMode
        applyPlainListAppearance()
        super.reloadData()
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
        let itemType = historyItem.getTableViewItemType()
        let cell = tableView.makeView(withIdentifier: itemType.identifier, owner: nil) as? HistoryListItem ?? itemType.makeItem()
        cell.setupCell(withHistoryTableView: self, forHistoryItem: historyItem, at: row)
        if let baseCell = cell as? HistoryItemBaseCellView {
            baseCell.bindHost(self, row: row, historyItem: historyItem)
        }
        if let cell = cell as? NSTableCellView {
            cell.setAccessibilityLabel(itemType.identifier.rawValue)
            cell.identifier = itemType.identifier
        }
        return cell as? NSView
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        if let delegate = historyDelegate {
            delegate.historyTableView(self, selectedDidChange: selected)
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
        guard let historyTableView = tableView as? HistoryTableView else { return 0 }
        let historyItem = historyListItems[row]
        let itemType = historyItem.getTableViewItemType()
        let displaySignature = HistoryItemText.displayCacheSignature(for: historyItem, listMode: historyTableView.listMode)
        
        if let height = cellHeightsCache.cellHeight(forId: historyItem.fsId, withCellIdentifier: itemType.identifier.rawValue, cellWidth: cellWidth, isRichText: isRichText, displaySignature: displaySignature) {
            return height
        }
        
        let height = historyItem.getTableViewItemType().getItemHeight(withHistoryTableView: historyTableView, forHistoryItem: historyItem)
        
        cellHeightsCache.storeCellHeight(height, forId: historyItem.fsId, withCellIdentifier: itemType.identifier.rawValue, cellWidth: cellWidth, isRichText: isRichText, displaySignature: displaySignature)
        
        return height
    }
    
}

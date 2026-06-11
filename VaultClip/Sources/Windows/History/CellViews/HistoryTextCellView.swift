//
//  HistoryTextCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

class HistoryTextCellView: HistoryItemBaseCellView, HistoryListItem {
    
    // MARK: - UI Constants
    
    static let padding = HistoryListTheme.metrics.textPadding
    
    static let textInset = NSEdgeInsetsZero // NSEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyTextCellView)
    }
    
    // MARK: - Methods
    
    override func commonInit() {
        super.commonInit()
        
        setupItemTextView()
    }
    
    func setupItemTextView() {
        // Define the maximum size of the text container, so that the text renders correctly when there needs to be clipping.
        // Width can be any value
        itemTextView.textContainer?.containerSize = NSSize(
            width: HistoryListTheme.metrics.listTextContainerWidth(cellWidth: 280, textPadding: Self.padding),
            height: Constants.panel.maxCellHeight - Self.padding.top - Self.padding.bottom - Self.textInset.yTotal - Self.contentViewInsets.yTotal
        )
        
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.isSelectable = false
        itemTextView.usingEdgeInsets = true
        itemTextView.alignment = .left
        itemTextView.textInset = Self.textInset
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.isHorizontallyResizable = false
        itemTextView.isVerticallyResizable = false
        
        // Add constraints for the item text view
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .leading, relatedBy: .equal, toItem: sourceAppIconView, attribute: .trailing, multiplier: 1, constant: HistoryItemBaseCellView.sourceAppIconSpacing))
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: Self.padding.top))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: itemTextView, attribute: .trailing, multiplier: 1, constant: Self.padding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: itemTextView, attribute: .bottom, multiplier: 1, constant: Self.padding.bottom))
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        updateTextContainerWidth(for: historyTableView)
        itemTextView.attributedText = HistoryItemText.getAttributedString(
            forItem: historyItem,
            usingItemRtf: historyTableView.isRichText,
            listMode: historyTableView.listMode
        )
        
        setHighlight(isSelected: historyTableView.isRowSelected(i))
        
        setupShortcutTextView(at: i, historyItem: historyItem)
    }
    
    static func getTextContainerWidth(cellWidth: CGFloat) -> CGFloat {
        HistoryListTheme.metrics.listTextContainerWidth(cellWidth: cellWidth, textPadding: Self.padding)
    }
    
    private func updateTextContainerWidth(for tableView: HistoryTableView) {
        let cellWidth = max(floor(tableView.cellWidth), 280)
        let width = Self.getTextContainerWidth(cellWidth: cellWidth)
        let height = Self.getTextContainerMaxHeight()
        itemTextView.textContainer?.containerSize = NSSize(width: width, height: height)
        itemTextView.textContainer?.widthTracksTextView = true
    }
    
    static func getTextContainerMaxHeight() -> CGFloat {
        return Constants.panel.maxCellHeight - Self.padding.top - Self.padding.bottom - Self.textInset.yTotal - Self.contentViewInsets.yTotal
    }
    
    static func getCellHeight(estTextHeight: CGFloat) -> CGFloat {
        // Get the max height of the text container
        let maxTextContainerHeight = getTextContainerMaxHeight()
        
        return min(estTextHeight, maxTextContainerHeight) + Self.padding.top + Self.padding.bottom + Self.textInset.yTotal + Self.contentViewInsets.yTotal
    }
    
    static func calculateCellHeight(historyTableView: HistoryTableView, historyItem: HistoryItem) -> CGFloat {
        // Column width can be 0 before the window lays out; avoid caching zero-height rows.
        let cellWidth = max(floor(historyTableView.cellWidth), 280)
        
        // Calculate the width of the text container
        let width = HistoryTextCellView.getTextContainerWidth(cellWidth: cellWidth)
        
        // Create an attributed string of the text
        let attrStr = HistoryItemText.getAttributedString(
            forItem: historyItem,
            usingItemRtf: historyTableView.isRichText,
            listMode: historyTableView.listMode
        )
        
        // Determine the height of the text
        let estTextHeight = attrStr.calculateSize(withMaxWidth: width).height
        
        // Add the padding back to get the height of the cell
        let height = HistoryTextCellView.getCellHeight(estTextHeight: estTextHeight)
        
        return ceil(height)
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        calculateCellHeight(historyTableView: historyTableView, historyItem: historyItem)
    }
    
    class func makeItem() -> HistoryListItem {
        return HistoryTextCellView(frame: .zero)
    }
}

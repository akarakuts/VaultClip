//
//  HistoryFileIconCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryFileIconCellView: HistoryItemBaseCellView, HistoryListItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyFileIconCellView)
    }
    static let textContainerInset = HistoryListTheme.metrics.fileTypeTextInset
    static let iconViewPadding = HistoryListTheme.metrics.fileTypeIconPadding
    static let iconSize = HistoryListTheme.metrics.fileTypeIconSize
    
    let iconView = NSImageView(frame: .zero)
    
    override func commonInit() {
        super.commonInit()
        
        contentView.addSubview(iconView)
        
        setupIconView()
        setupItemTextView()
    }
    
    func setupIconView() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: Self.iconSize.width).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: Self.iconSize.height).isActive = true
        iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        iconView.leadingAnchor.constraint(
            equalTo: sourceAppIconView.trailingAnchor,
            constant: HistoryItemBaseCellView.sourceAppIconSpacing
        ).isActive = true
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.usingEdgeInsets = true
        itemTextView.textInset = Self.textContainerInset
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.isVerticallyResizable = false
        itemTextView.isHorizontallyResizable = false
        itemTextView.alignment = .left
        itemTextView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Self.iconViewPadding.right).isActive = true
        contentView.trailingAnchor.constraint(equalTo: itemTextView.trailingAnchor, constant: Self.iconViewPadding.right).isActive = true
        itemTextView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        itemTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        guard let fileUrl = historyItem.getFileUrl() else { return }
        iconView.image = historyItem.getFileIcon()
        setupShortcutTextView(at: i, historyItem: historyItem)
        let displayText = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatFileUrl(fileUrl),
            for: historyItem,
            listMode: historyTableView.listMode
        )
        itemTextView.attributedText = displayText
        itemTextView.constraint(withIdentifier: "height")?.constant = Self.getFileNameTextViewHeight(
            withCellWidth: floor(historyTableView.cellWidth),
            forHistoryItem: historyItem,
            listMode: historyTableView.listMode
        )
        setHighlight(isSelected: historyTableView.isRowSelected(i))
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        // Calculate the width of the cell
        let cellWidth = floor(historyTableView.cellWidth)
        
        // Calculate the text view height
        let textViewHeight = getFileNameTextViewHeight(withCellWidth: cellWidth, forHistoryItem: historyItem, listMode: historyTableView.listMode)
        
        // Calculate minimum cell height
        let minCellHeight = iconSize.height + contentViewInsets.yTotal + iconViewPadding.yTotal
        
        // Add the padding back to get the height of the cell
        let height = max(textViewHeight + contentViewInsets.yTotal, minCellHeight)
        
        return ceil(height)
    }
    
    static func getFileNameTextViewHeight(withCellWidth cellWidth: CGFloat, forHistoryItem historyItem: HistoryItem, listMode: HistoryListMode) -> CGFloat {
        guard let fileUrl = historyItem.getFileUrl() else {
            return textContainerInset.yTotal
        }
        let width = cellWidth
            - contentViewInsets.xTotal
            - iconSize.width
            - textContainerInset.xTotal
            - iconViewPadding.xTotal
            - sourceAppIconSize
            - sourceAppIconSpacing
            - sourceAppIconTrailingInset
        
        let attrStr = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatFileUrl(fileUrl),
            for: historyItem,
            listMode: listMode
        )
        
        // Get the max height of the text container
        let maxTextContainerHeight = Constants.panel.maxCellHeight - contentViewInsets.yTotal - textContainerInset.yTotal
        
        // Determine the height of the text view (capping the cell height)
        let estHeight = attrStr.calculateSize(withMaxWidth: width).height
        
        return min(estHeight, maxTextContainerHeight) + textContainerInset.yTotal
    }
    
    static func makeItem() -> HistoryListItem {
        return HistoryFileIconCellView(frame: .zero)
    }
}

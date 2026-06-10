//
//  HistoryPdfCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

class HistoryPdfCellView: HistoryItemBaseCellView, HistoryListItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyPdfCellView)
    }
    
    static let textContainerInset = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let iconViewPadding = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let iconSize = NSSize(width: 32, height: 32)
    
    var iconView: NSImageView!
    
    override func commonInit() {
        super.commonInit()
        
        iconView = NSImageView(frame: .zero)
        contentView.addSubview(iconView)
        
        setupIconView()
        setupItemTextView()
    }
    
    func setupIconView() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: Self.iconSize.width).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: Self.iconSize.height).isActive = true
        iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        contentView.addConstraint(NSLayoutConstraint(item: iconView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.iconViewPadding.left))
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.usingEdgeInsets = true
        itemTextView.textInset = Self.textContainerInset
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.isVerticallyResizable = false
        itemTextView.isHorizontallyResizable = false
        itemTextView.alignment = .left
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .leading, relatedBy: .equal, toItem: iconView, attribute: .trailing, multiplier: 1, constant: Self.iconViewPadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: itemTextView, attribute: .trailing, multiplier: 1, constant: 0))
        itemTextView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        itemTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        iconView.image = historyItem.getPdfIcon()
        setupShortcutTextView(at: i, historyItem: historyItem)
        let label = historyItem.getPdfDisplayString() ?? "PDF document"
        let displayText = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatPdfDisplay(label),
            for: historyItem,
            listMode: historyTableView.listMode
        )
        itemTextView.attributedText = displayText
        itemTextView.constraint(withIdentifier: "height")?.constant = Self.labelHeight(
            withCellWidth: floor(historyTableView.cellWidth),
            forHistoryItem: historyItem,
            listMode: historyTableView.listMode,
            label: label
        )
        setHighlight(isSelected: historyTableView.isRowSelected(i))
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        let cellWidth = floor(historyTableView.cellWidth)
        let label = historyItem.getPdfDisplayString() ?? "PDF document"
        let textViewHeight = labelHeight(withCellWidth: cellWidth, forHistoryItem: historyItem, listMode: historyTableView.listMode, label: label)
        let minCellHeight = iconSize.height + contentViewInsets.yTotal + iconViewPadding.yTotal
        return ceil(max(textViewHeight + contentViewInsets.yTotal, minCellHeight))
    }
    
    static func labelHeight(withCellWidth cellWidth: CGFloat, forHistoryItem historyItem: HistoryItem, listMode: HistoryListMode, label: String) -> CGFloat {
        let width = cellWidth - contentViewInsets.xTotal - iconSize.width - textContainerInset.xTotal - iconViewPadding.xTotal
        let attrStr = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatPdfDisplay(label),
            for: historyItem,
            listMode: listMode
        )
        let maxTextContainerHeight = Constants.panel.maxCellHeight - contentViewInsets.yTotal - textContainerInset.yTotal
        let estHeight = attrStr.calculateSize(withMaxWidth: width).height
        return min(estHeight, maxTextContainerHeight) + textContainerInset.yTotal
    }
    
    static func makeItem() -> HistoryListItem {
        HistoryPdfCellView(frame: .zero)
    }
}

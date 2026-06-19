//
//  HistoryTiffCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryTiffCellView: HistoryItemBaseCellView, HistoryListItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyTiffCellView)
    }
    
    static let imagePadding = HistoryListTheme.metrics.imageCellPadding
    
    let tiffView = NSImageView(frame: .zero)
    
    override func commonInit() {
        super.commonInit()
        
        itemTextView.isHidden = true
        
        contentView.addSubview(tiffView)
        
        setupTiffView()
    }
    
    func setupTiffView() {
        tiffView.translatesAutoresizingMaskIntoConstraints = false
        tiffView.imageAlignment = .alignTopLeft
        tiffView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            tiffView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.imagePadding.top),
            tiffView.leadingAnchor.constraint(equalTo: sourceAppIconView.trailingAnchor, constant: HistoryItemBaseCellView.sourceAppIconSpacing),
            contentView.trailingAnchor.constraint(equalTo: tiffView.trailingAnchor, constant: Self.imagePadding.right),
            contentView.bottomAnchor.constraint(equalTo: tiffView.bottomAnchor, constant: Self.imagePadding.bottom),
        ])
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        setupShortcutTextView(at: i, historyItem: historyItem)
        setHighlight(isSelected: historyTableView.isRowSelected(i))
        tiffView.image = historyItem.getImage()
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        let cellWidth = floor(historyTableView.cellWidth)
        
        guard let image = historyItem.getImage() else {
            return HistoryListTheme.metrics.imageCellMinHeight + imagePadding.yTotal + contentViewInsets.yTotal
        }
        
        let imageWidth = max(
            1,
            cellWidth
                - imagePadding.xTotal
                - contentViewInsets.xTotal
                - sourceAppIconSize
                - sourceAppIconSpacing
                - sourceAppIconTrailingInset
        )
        let pixelSize = HistoryItem.displayPixelSize(of: image)
        let aspectHeight = pixelSize.height * imageWidth / max(pixelSize.width, 1)
        let maxHeight = max(historyTableView.visibleRect.height, Constants.panel.maxCellHeight)
        let imageHeight = min(aspectHeight, maxHeight)
        
        return ceil(imageHeight + imagePadding.yTotal + contentViewInsets.yTotal)
    }
    
    static func makeItem() -> HistoryListItem {
        return HistoryTiffCellView(frame: .zero)
    }
}

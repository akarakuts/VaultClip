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
    
    static let imagePadding = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
    
    var tiffView: NSImageView!
    
    override func commonInit() {
        super.commonInit()
        
        itemTextView.isHidden = true
        
        tiffView = NSImageView(frame: .zero)
        contentView.addSubview(tiffView)
        
        setupTiffView()
    }
    
    func setupTiffView() {
        tiffView.translatesAutoresizingMaskIntoConstraints = false
        tiffView.imageAlignment = .alignTopLeft
        tiffView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addConstraint(NSLayoutConstraint(item: tiffView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: Self.imagePadding.top))
        contentView.addConstraint(NSLayoutConstraint(item: tiffView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.imagePadding.left))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: tiffView, attribute: .trailing, multiplier: 1, constant: Self.imagePadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: tiffView, attribute: .bottom, multiplier: 1, constant: Self.imagePadding.bottom))
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        setupShortcutTextView(at: i, historyItem: historyItem)
        setHighlight(isSelected: historyTableView.isRowSelected(i))
        tiffView.image = historyItem.getImage()
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        let cellWidth = floor(historyTableView.cellWidth)
        
        guard let image = historyItem.getImage() else {
            return 50 + imagePadding.yTotal + contentViewInsets.yTotal
        }
        
        let imageWidth = max(1, cellWidth - imagePadding.xTotal - contentViewInsets.xTotal)
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

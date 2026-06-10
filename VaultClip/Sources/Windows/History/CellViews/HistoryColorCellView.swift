//
//  HistoryColorCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryColorCellView: HistoryTextCellView {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyColorCellView)
    }
    
    override func commonInit() {
        super.commonInit()
        
        contentView.usesDynamicBackgroundColor = false
    }
    
    override func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        super.setupCell(withHistoryTableView: historyTableView, forHistoryItem: historyItem, at: i)
        
        if let color = historyItem.getColor()?.withAlphaComponent(1) {
            contentView.layer?.backgroundColor = color.cgColor
        }
    }
    
    override class func makeItem() -> HistoryListItem {
        return HistoryColorCellView(frame: .zero)
    }
}

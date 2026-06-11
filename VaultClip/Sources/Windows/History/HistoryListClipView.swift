//
//  HistoryListClipView.swift
//  VaultClip
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

/// Clip view for the history list — owns table width so tab reloads cannot shift rows horizontally.
final class HistoryListClipView: NSClipView {
    private var isEnforcingWidth = false
    
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        rect.origin.x = 0
        return rect
    }
    
    override func setBoundsOrigin(_ newOrigin: NSPoint) {
        super.setBoundsOrigin(NSPoint(x: 0, y: newOrigin.y))
    }
    
    override func layout() {
        super.layout()
        enforceDocumentWidth()
    }
    
    func enforceDocumentWidth() {
        guard !isEnforcingWidth else { return }
        guard let documentView = documentView else { return }
        
        let width = floor(bounds.width)
        guard width > 0 else { return }
        
        isEnforcingWidth = true
        defer { isEnforcingWidth = false }
        
        var documentFrame = documentView.frame
        var changed = false
        
        if abs(documentFrame.origin.x) > 0.5 {
            documentFrame.origin.x = 0
            changed = true
        }
        if abs(documentFrame.width - width) > 0.5 {
            documentFrame.size.width = width
            changed = true
        }
        if changed {
            documentView.frame = documentFrame
        }
        
        if let tableView = documentView as? NSTableView {
            tableView.columnAutoresizingStyle = .noColumnAutoresizing
            if let column = tableView.tableColumns.first,
               abs(column.width - width) > 0.5 {
                column.width = width
            }
        }
        
        if abs(bounds.origin.x) > 0.5 {
            super.setBoundsOrigin(NSPoint(x: 0, y: bounds.origin.y))
        }
    }
}

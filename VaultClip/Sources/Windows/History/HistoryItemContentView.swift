//
//  HistoryItemContentView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

/// Card background inside a history row; updates border and shadow for light/dark mode.
class HistoryItemContentView: NSView {
    
    var usesDynamicBackgroundColor = true
    var isRowSelected = false {
        didSet { needsDisplay = true; updateLayerAppearance() }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func updateLayer() {
        super.updateLayer()
        updateLayerAppearance()
    }
    
    private func updateLayerAppearance() {
        if usesDynamicBackgroundColor {
            layer?.backgroundColor = NSColor(named: NSColor.Name("TextBackgroundColor"))?.cgColor
        }
        
        let border = HistoryListTheme.colors.cardBorder(isSelected: isRowSelected)
        layer?.borderColor = border.cgColor
        layer?.borderWidth = isRowSelected
            ? HistoryListTheme.metrics.selectedCardBorderWidth
            : HistoryListTheme.metrics.cardBorderWidth
        
        if isRowSelected {
            layer?.shadowColor = NSColor.black.cgColor
            layer?.shadowOpacity = 0.14
            layer?.shadowRadius = 5
            layer?.shadowOffset = CGSize(width: 0, height: -1)
        } else {
            layer?.shadowOpacity = 0
            layer?.shadowRadius = 0
        }
    }
}

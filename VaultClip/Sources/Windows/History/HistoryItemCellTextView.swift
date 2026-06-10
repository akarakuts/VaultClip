//
//  HistoryItemCellTextView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryItemCellTextView: NSTextView {
    
    override func mouseDown(with event: NSEvent) {
        self.nextResponder?.mouseDown(with: event)
    }
    
    var textInset: NSEdgeInsets = NSEdgeInsetsZero {
        didSet {
            textContainerInset = CGSize(width: (textInset.left + textInset.right)/2, height: (textInset.top + textInset.bottom)/2)
        }
    }
    
    var usingEdgeInsets = false
    
    override var textContainerOrigin: NSPoint {
        if usingEdgeInsets {
            return NSPoint(x: textInset.left, y: textInset.top)
        }
        else {
            return super.textContainerOrigin
        }
    }
}

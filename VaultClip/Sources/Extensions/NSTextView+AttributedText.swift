//
//  NSTextView+AttributedText.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSTextView {
    
    var attributedText: NSAttributedString! {
        get {
            guard let textStorage = textStorage else {
                return nil
            }
            
            return textStorage.attributedSubstring(from: NSRange(location: 0, length: textStorage.string.count))
        }
        set(str) {
            // Without a text storage the view simply cannot render text, so
            // ignore the write rather than crashing the whole application.
            guard let textStorage = textStorage else { return }
            let str = str ?? NSAttributedString(string: "")
            textStorage.setAttributedString(str)
        }
    }
}

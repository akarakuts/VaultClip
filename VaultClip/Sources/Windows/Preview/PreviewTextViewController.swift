//
//  PreviewTextViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class PreviewTextViewController: NSViewController, PreviewViewController {
    
    static let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "PreviewTextViewController")
    
    @IBOutlet var textView: NSTextView!
    
    let padding = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    @IBOutlet var topPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var bottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var rightPaddingConstraint: NSLayoutConstraint!
    @IBOutlet var leftPaddingConstraint: NSLayoutConstraint!
    
    var isRichText: Bool = false
    private var previewItem: HistoryItem?
    private var passwordRevealed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextView()
        
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.borderWidth = padding.left
        
        topPaddingConstraint.constant = padding.top
        bottomPaddingConstraint.constant = padding.bottom
        rightPaddingConstraint.constant = padding.right
        leftPaddingConstraint.constant = padding.left
    }
    
    func setupTextView() {
        textView.textContainerInset = NSSize(width: 15, height: 15)
        textView.textContainer?.lineFragmentPadding = 0
        textView.drawsBackground = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
    }
    
    func configureView(forItem item: HistoryItem) -> NSRect {
        previewItem = item
        passwordRevealed = false
        updatePreviewText()
        let text = textView.attributedString()
        return calculateWindowFrame(forText: text)
    }
    
    private func updatePreviewText() {
        guard let item = previewItem else { return }
        if item.isPassword && !passwordRevealed {
            textView.string = HistoryItemText.passwordMask + "\n\n" + L10n.previewClickToReveal
            textView.isSelectable = false
            return
        }
        let text = HistoryItemText.getAttributedString(
            forItem: item,
            usingItemRtf: isRichText,
            listMode: item.isPassword ? .passwords : .history,
            revealPassword: passwordRevealed
        )
        textView.attributedText = text
        textView.isSelectable = !item.isPassword
    }
    
    override func mouseDown(with event: NSEvent) {
        if let item = previewItem, item.isPassword, !passwordRevealed {
            passwordRevealed = true
            updatePreviewText()
            return
        }
        super.mouseDown(with: event)
    }
    
    func calculateWindowFrame(forText text: NSAttributedString) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen.main!
        let maxWindowWidth = screen.frame.width * 0.8
        let maxWindowHeight = screen.frame.height * 0.8
        
        let maxTextContainerWidth = maxWindowWidth - padding.xTotal - textView.textContainerInset.width * 2
        
        let bRect = text.calculateSize(withMaxWidth: maxTextContainerWidth)
        
        let windowWidth = bRect.width + padding.xTotal + textView.textContainerInset.width * 2
        
        let windowHeight = min(maxWindowHeight, bRect.height + padding.yTotal + textView.textContainerInset.height * 2)
        
        let center = NSPoint(x: screen.frame.midX - windowWidth / 2, y: screen.frame.midY - windowHeight / 2)
        
        return NSRect(origin: center, size: NSSize(width: windowWidth, height: windowHeight))
    }
}

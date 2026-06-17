//
//  HelpInstructionsViewController.swift
//  VaultClip
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

/// Help content — built in code so embed segues always show localized text (storyboard placeholders are ignored).
class HelpInstructionsViewController: NSViewController {

    private let titleField = NSTextField(labelWithString: "")
    private let bodyTextView = NSTextView()

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 480))

        let iconView = NSImageView()
        iconView.image = NSImage(named: "VaultClipIconColored")
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleField.font = NSFont.systemFont(ofSize: 25, weight: .medium)
        titleField.alignment = .center
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.setAccessibilityIdentifier("howToUseLabel")

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        bodyTextView.isEditable = false
        bodyTextView.isSelectable = true
        bodyTextView.drawsBackground = false
        bodyTextView.isRichText = false
        bodyTextView.font = NSFont.systemFont(ofSize: 12)
        bodyTextView.textColor = .labelColor
        bodyTextView.textContainer?.widthTracksTextView = true
        bodyTextView.textContainerInset = NSSize(width: 2, height: 4)
        bodyTextView.autoresizingMask = [.width]
        bodyTextView.setAccessibilityIdentifier("helpInstructionsBody")
        scrollView.documentView = bodyTextView

        root.addSubview(iconView)
        root.addSubview(titleField)
        root.addSubview(scrollView)

        let inset: CGFloat = 20
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: root.topAnchor, constant: inset),
            iconView.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),

            titleField.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: inset),
            titleField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -inset),

            scrollView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: inset),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -inset),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -inset),
        ])

        view = root
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        refreshContent()
    }

    func refreshContent() {
        view.window?.title = L10n.helpWindowTitle
        titleField.stringValue = L10n.helpHowToUseTitle
        bodyTextView.string = L10n.helpInstructionsBody
    }
}

//
// EmbeddedPreviewView — side/bottom preview pane content shell (U21/U22).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class EmbeddedPreviewView: NSView {
    private let scroll = NSScrollView()
    private let textView = NSTextView()
    private let placeholder = NSTextField(labelWithString: "")
    private let actions = NSStackView()
    var onPaste: (() -> Void)?
    var onCopy: (() -> Void)?
    var onEdit: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func showEmpty() {
        textView.string = ""
        placeholder.isHidden = false
        placeholder.stringValue = L10n.commandTitle(for: "command.togglePreview")
        actions.isHidden = true
    }

    func showText(_ text: String, isPassword: Bool) {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty || isPassword else {
            showEmpty()
            return
        }
        placeholder.isHidden = true
        actions.isHidden = false
        textView.string = isPassword ? "••••••••" : text
        textView.isEditable = false
        textView.isSelectable = !isPassword
    }

    private func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        setAccessibilityIdentifier(Accessibility.identifiers.panelPreviewSplit)

        let separator = NSBox(frame: .zero)
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        placeholder.textColor = .secondaryLabelColor
        placeholder.alignment = .center
        placeholder.maximumNumberOfLines = 3
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholder)

        textView.isRichText = false
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = .textBackgroundColor
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        actions.orientation = .horizontal
        actions.spacing = 8
        actions.translatesAutoresizingMaskIntoConstraints = false
        let paste = NSButton(title: L10n.command_paste, target: self, action: #selector(pasteTapped))
        paste.keyEquivalent = "\r"
        let copy = NSButton(title: L10n.command_copy, target: self, action: #selector(copyTapped))
        let edit = NSButton(title: L10n.command_editBeforePaste, target: self, action: #selector(editTapped))
        [paste, copy, edit].forEach { actions.addArrangedSubview($0) }
        addSubview(actions)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scroll.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            scroll.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -8),
            actions.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            actions.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            actions.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            placeholder.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        showEmpty()
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    @objc private func pasteTapped() { onPaste?() }
    @objc private func copyTapped() { onCopy?() }
    @objc private func editTapped() { onEdit?() }
}

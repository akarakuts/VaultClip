//
// EmbeddedPreviewView — in-panel preview pane per item kind with inline edit-before-paste (U21/U22/U24).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

enum EmbeddedPreviewContent {
    case text(String, monospaced: Bool)
    case link(host: String, url: String)
    case image(NSImage, caption: String)
    case color(NSColor, caption: String)
    case files([URL])
    case password(comment: String, login: String, url: String)
}

final class EmbeddedPreviewView: NSView {
    private let headerLabel = NSTextField(labelWithString: "")
    private let scroll = NSScrollView()
    private let textView = NSTextView()
    private let imageView = NSImageView()
    private let swatch = NSView()
    private let captionLabel = NSTextField(labelWithString: "")
    private let placeholder = NSTextField(labelWithString: "")
    private let actions = NSStackView()
    private let pasteButton = NSButton(title: "", target: nil, action: nil)
    private let copyButton = NSButton(title: "", target: nil, action: nil)
    private let editButton = NSButton(title: "", target: nil, action: nil)
    private let openButton = NSButton(title: "", target: nil, action: nil)
    private var originalText = ""
    private(set) var isEditing = false

    var onPaste: (() -> Void)?
    var onCopy: (() -> Void)?
    var onEdit: (() -> Void)?
    var onOpen: (() -> Void)?

    var editedText: String { textView.string }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func showEmpty() {
        endEditing()
        setVisible(text: false, image: false, swatch: false)
        headerLabel.stringValue = ""
        captionLabel.stringValue = ""
        placeholder.isHidden = false
        placeholder.stringValue = Self.ru ? "Нет выделенного элемента" : "Nothing selected"
        actions.isHidden = true
    }

    func show(_ content: EmbeddedPreviewContent) {
        endEditing()
        placeholder.isHidden = true
        actions.isHidden = false
        editButton.isHidden = true
        openButton.isHidden = true
        copyButton.isHidden = false
        textView.font = .systemFont(ofSize: 13)
        switch content {
        case .text(let text, let monospaced):
            headerLabel.stringValue = Self.ru ? "Текст" : "Text"
            showBody(text, font: monospaced
                ? .monospacedSystemFont(ofSize: 12, weight: .regular)
                : .systemFont(ofSize: 13))
            captionLabel.stringValue = Self.ru ? "\(text.count) симв." : "\(text.count) chars"
            editButton.isHidden = false
        case .link(let host, let url):
            headerLabel.stringValue = host
            showBody(url, font: .systemFont(ofSize: 13))
            captionLabel.stringValue = Self.ru ? "Ссылка" : "Link"
            openButton.isHidden = false
            editButton.isHidden = false
        case .image(let image, let caption):
            headerLabel.stringValue = Self.ru ? "Изображение" : "Image"
            setVisible(text: false, image: true, swatch: false)
            imageView.image = image
            captionLabel.stringValue = caption
        case .color(let color, let caption):
            headerLabel.stringValue = Self.ru ? "Цвет" : "Color"
            setVisible(text: false, image: false, swatch: true)
            swatch.layer?.backgroundColor = color.cgColor
            captionLabel.stringValue = caption
        case .files(let urls):
            headerLabel.stringValue = urls.count == 1
                ? urls[0].lastPathComponent
                : (Self.ru ? "Файлы: \(urls.count)" : "\(urls.count) files")
            let paths = urls.map { ($0.path as NSString).abbreviatingWithTildeInPath }.joined(separator: "\n")
            showBody(paths, font: .systemFont(ofSize: 12))
            let exists = urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) }
            captionLabel.stringValue = exists ? "" : (Self.ru ? "Файл перемещён или удалён" : "File moved or deleted")
            openButton.isHidden = !exists
        case .password(let comment, let login, let url):
            headerLabel.stringValue = comment.isEmpty ? (Self.ru ? "Пароль" : "Password") : comment
            var lines: [String] = []
            if !login.isEmpty { lines.append("\(Self.ru ? "Логин" : "Login"): \(login)") }
            if !url.isEmpty { lines.append("URL: \(url)") }
            lines.append("\(Self.ru ? "Пароль" : "Password"): ••••••••")
            showBody(lines.joined(separator: "\n"), font: .systemFont(ofSize: 13))
            captionLabel.stringValue = ""
        }
    }

    /// Inline editor; ⏎ / Paste then pastes `editedText` (U24).
    func beginEditing() {
        guard !scroll.isHidden, !isEditing else { return }
        isEditing = true
        originalText = textView.string
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        window?.makeFirstResponder(textView)
        textView.selectAll(nil)
        editButton.title = Self.ru ? "Отменить" : "Cancel"
        pasteButton.title = Self.ru ? "Вставить ⌘⏎" : "Paste ⌘⏎"
        copyButton.isHidden = true
    }

    func endEditing() {
        guard isEditing else { return }
        isEditing = false
        textView.string = originalText
        textView.isEditable = false
        textView.drawsBackground = false
        editButton.title = L10n.command_editBeforePaste
        pasteButton.title = L10n.command_paste
        copyButton.isHidden = false
    }

    private func showBody(_ text: String, font: NSFont) {
        setVisible(text: true, image: false, swatch: false)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = font
        textView.string = text
        textView.scrollToBeginningOfDocument(nil)
    }

    private func setVisible(text: Bool, image: Bool, swatch showSwatch: Bool) {
        scroll.isHidden = !text
        imageView.isHidden = !image
        swatch.isHidden = !showSwatch
    }

    private static var ru: Bool { Locale.current.language.languageCode?.identifier == "ru" }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        setAccessibilityIdentifier(Accessibility.identifiers.panelPreviewSplit)

        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.lineBreakMode = .byTruncatingMiddle
        captionLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        captionLabel.textColor = .secondaryLabelColor
        captionLabel.lineBreakMode = .byTruncatingTail
        placeholder.textColor = .secondaryLabelColor
        placeholder.alignment = .center

        textView.isRichText = false
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 2, height: 4)
        textView.textContainer?.widthTracksTextView = true
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder

        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        // Image/text intrinsic sizes must not out-rank the window size (priority 500).
        for axis in [NSLayoutConstraint.Orientation.horizontal, .vertical] {
            imageView.setContentCompressionResistancePriority(.defaultLow - 100, for: axis)
            imageView.setContentHuggingPriority(.defaultLow - 100, for: axis)
            scroll.setContentCompressionResistancePriority(.defaultLow - 100, for: axis)
        }
        for label in [headerLabel, captionLabel, placeholder] {
            label.setContentCompressionResistancePriority(.defaultLow - 100, for: .horizontal)
        }
        swatch.wantsLayer = true
        swatch.layer?.cornerRadius = 10
        swatch.layer?.borderWidth = 1
        swatch.layer?.borderColor = NSColor.separatorColor.cgColor

        // No key equivalent: ⏎ is routed by PanelLocalKeyMonitor, a second binding would double-paste.
        configure(pasteButton, title: L10n.command_paste, action: #selector(pasteTapped))
        configure(copyButton, title: L10n.command_copy, action: #selector(copyTapped))
        configure(editButton, title: L10n.command_editBeforePaste, action: #selector(editTapped))
        configure(openButton, title: Self.ru ? "Открыть" : "Open", action: #selector(openTapped))
        actions.orientation = .horizontal
        actions.spacing = 6
        [pasteButton, copyButton, openButton, editButton].forEach { actions.addArrangedSubview($0) }

        for sub in [headerLabel, scroll, imageView, swatch, captionLabel, placeholder, actions] as [NSView] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sub)
        }

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            scroll.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            scroll.bottomAnchor.constraint(equalTo: captionLabel.topAnchor, constant: -4),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            imageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            imageView.bottomAnchor.constraint(equalTo: captionLabel.topAnchor, constant: -6),

            swatch.centerXAnchor.constraint(equalTo: centerXAnchor),
            swatch.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            swatch.widthAnchor.constraint(equalToConstant: 72),
            swatch.heightAnchor.constraint(equalToConstant: 72),

            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            captionLabel.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -6),

            actions.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            actions.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            actions.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            placeholder.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        showEmpty()
    }

    private func configure(_ button: NSButton, title: String, action: Selector) {
        button.title = title
        button.setContentCompressionResistancePriority(.defaultLow - 100, for: .horizontal)
        (button.cell as? NSButtonCell)?.lineBreakMode = .byTruncatingTail
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        button.target = self
        button.action = action
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        layer?.borderColor = NSColor.separatorColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    @objc private func pasteTapped() { onPaste?() }
    @objc private func copyTapped() { onCopy?() }
    @objc private func openTapped() { onOpen?() }
    @objc private func editTapped() {
        if isEditing {
            endEditing()
        } else {
            onEdit?()
        }
    }
}

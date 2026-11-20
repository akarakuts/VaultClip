//
// HistoryRowView — single compact row: leading art, title/subtitle, shortcut, action overlay (U11/U15).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class HistoryRowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("HistoryRowView")

    private let leadingView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let shortcutLabel = NSTextField(labelWithString: "")
    private let accessoryView = NSImageView()
    private let fadeView = NSView()
    private let actionsStack = NSStackView()
    private var actionButtons: [RowActionButtonID: NSButton] = [:]
    var onAction: ((RowActionButtonID) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func apply(
        presentation: RowPresentation,
        shortcutNumber: Int?,
        textSize: TextSizePreference,
        isFavorite: Bool,
        isPassword: Bool,
        tab: HistoryListMode = .history,
        showsActions: Bool = false
    ) {
        titleLabel.stringValue = presentation.title
        subtitleLabel.stringValue = presentation.subtitle
        titleLabel.font = PanelTheme.titleFont(for: textSize)
        subtitleLabel.font = PanelTheme.subtitleFont(for: textSize)
        shortcutLabel.font = PanelTheme.shortcutFont(for: textSize)
        if let n = shortcutNumber {
            shortcutLabel.stringValue = n == 0 ? "⌘0" : "⌘\(n)"
            shortcutLabel.isHidden = showsActions
        } else {
            shortcutLabel.isHidden = true
        }
        if isPassword {
            accessoryView.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
            accessoryView.isHidden = false
        } else if isFavorite {
            accessoryView.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
            accessoryView.isHidden = false
        } else {
            accessoryView.isHidden = true
        }
        leadingView.image = LeadingArtwork.image(for: presentation.kind, sourceBundleId: presentation.sourceBundleId)
        toolTip = presentation.kind == .password ? nil : "\(presentation.title)\n\(presentation.subtitle)"
        setAccessibilityLabel(presentation.accessibilityLabel)
        rebuildActions(
            kind: presentation.kind,
            isFavorite: isFavorite,
            tab: isPassword ? .passwords : tab,
            visible: showsActions
        )
    }

    func setActionsVisible(_ visible: Bool) {
        fadeView.isHidden = !visible
        actionsStack.isHidden = !visible
        if visible {
            shortcutLabel.isHidden = true
        }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            let emphasized = backgroundStyle == .emphasized
            titleLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .labelColor
            subtitleLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
            shortcutLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .tertiaryLabelColor
            if emphasized {
                setActionsVisible(true)
            }
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        setActionsVisible(true)
    }

    override func mouseExited(with event: NSEvent) {
        if backgroundStyle != .emphasized {
            setActionsVisible(false)
            if !shortcutLabel.stringValue.isEmpty {
                shortcutLabel.isHidden = false
            }
        }
    }

    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        actionButtons.keys.sorted { $0.rawValue < $1.rawValue }.compactMap { id in
            guard let button = actionButtons[id] else { return nil }
            return NSAccessibilityCustomAction(name: button.toolTip ?? id.rawValue) { [weak self] in
                self?.onAction?(id)
                return true
            }
        }
    }

    private func rebuildActions(kind: ItemKind, isFavorite: Bool, tab: HistoryListMode, visible: Bool) {
        actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        let buttons = RowActionOverlay.buttons(kind: kind, isFavorite: isFavorite, tab: tab)
        for spec in buttons {
            let button = NSButton(image: NSImage(systemSymbolName: spec.symbolName, accessibilityDescription: nil) ?? NSImage(), target: self, action: #selector(actionClicked(_:)))
            button.bezelStyle = .inline
            button.isBordered = false
            button.imagePosition = .imageOnly
            button.toolTip = RowActionOverlay.tooltip(for: spec)
            button.identifier = NSUserInterfaceItemIdentifier(spec.id.rawValue)
            button.setAccessibilityElement(false)
            button.refusesFirstResponder = true
            button.widthAnchor.constraint(equalToConstant: 24).isActive = true
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            actionsStack.addArrangedSubview(button)
            actionButtons[spec.id] = button
        }
        setActionsVisible(visible)
    }

    @objc private func actionClicked(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue,
              let id = RowActionButtonID(rawValue: raw) else { return }
        onAction?(id)
    }

    private func setup() {
        identifier = Self.identifier
        leadingView.translatesAutoresizingMaskIntoConstraints = false
        leadingView.imageScaling = .scaleProportionallyUpOrDown
        leadingView.wantsLayer = true
        leadingView.layer?.cornerRadius = PanelTheme.Radius.thumbnail

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.textColor = .secondaryLabelColor
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.textColor = .tertiaryLabelColor
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        fadeView.translatesAutoresizingMaskIntoConstraints = false
        fadeView.wantsLayer = true
        fadeView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.85).cgColor
        fadeView.isHidden = true

        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.orientation = .horizontal
        actionsStack.spacing = 2
        actionsStack.isHidden = true

        addSubview(leadingView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(shortcutLabel)
        addSubview(accessoryView)
        addSubview(fadeView)
        addSubview(actionsStack)

        NSLayoutConstraint.activate([
            leadingView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PanelTheme.Spacing.sm),
            leadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingView.widthAnchor.constraint(equalToConstant: 28),
            leadingView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: leadingView.trailingAnchor, constant: PanelTheme.Spacing.sm),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.leadingAnchor, constant: -4),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6),

            shortcutLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PanelTheme.Spacing.sm),
            shortcutLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            accessoryView.trailingAnchor.constraint(equalTo: shortcutLabel.leadingAnchor, constant: -6),
            accessoryView.centerYAnchor.constraint(equalTo: centerYAnchor),
            accessoryView.widthAnchor.constraint(equalToConstant: 12),
            accessoryView.heightAnchor.constraint(equalToConstant: 12),

            actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PanelTheme.Spacing.sm),
            actionsStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            fadeView.trailingAnchor.constraint(equalTo: actionsStack.leadingAnchor, constant: -4),
            fadeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            fadeView.widthAnchor.constraint(equalToConstant: 24),
            fadeView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}

enum LeadingArtwork {
    static func image(for kind: ItemKind, sourceBundleId: String?) -> NSImage? {
        switch kind {
        case .image:
            return NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        case .color:
            return NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
        case .file:
            return NSImage(systemSymbolName: "doc", accessibilityDescription: nil) // count ignored for icon
        case .pdf:
            return NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: nil)
        case .link:
            return NSImage(systemSymbolName: "link", accessibilityDescription: nil)
        case .password:
            return NSImage(systemSymbolName: "key.fill", accessibilityDescription: nil)
        case .text, .richText:
            if let bundleId = sourceBundleId {
                return SourceAppIconProvider.icon(forBundleId: bundleId)
            }
            return NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: nil)
        }
    }
}

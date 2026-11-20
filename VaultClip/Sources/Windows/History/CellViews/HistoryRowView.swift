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
    private let actionsStack = NSStackView()
    private var actionButtons: [RowActionButtonID: NSButton] = [:]
    private var textToAccessory: [NSLayoutConstraint] = []
    private var textToActions: [NSLayoutConstraint] = []
    private var isHovering = false
    private var isRowSelected = false
    var onAction: ((RowActionButtonID) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // swiftlint:disable:next function_parameter_count
    func apply(
        presentation: RowPresentation,
        artwork: NSImage?,
        shortcutNumber: Int?,
        textSize: TextSizePreference,
        isFavorite: Bool,
        isPassword: Bool,
        tab: HistoryListMode = .history
    ) {
        titleLabel.stringValue = presentation.title.isEmpty ? " " : presentation.title
        subtitleLabel.stringValue = presentation.subtitle
        titleLabel.font = PanelTheme.titleFont(for: textSize)
        subtitleLabel.font = PanelTheme.subtitleFont(for: textSize)
        shortcutLabel.font = PanelTheme.shortcutFont(for: textSize)
        if let n = shortcutNumber {
            shortcutLabel.stringValue = "⌘\(n)"
        } else {
            shortcutLabel.stringValue = ""
        }
        if isPassword {
            accessoryView.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
            accessoryView.isHidden = false
        } else if isFavorite {
            accessoryView.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
            accessoryView.isHidden = false
        } else {
            accessoryView.image = nil
            accessoryView.isHidden = true
        }
        leadingView.image = artwork
            ?? LeadingArtwork.image(for: presentation.kind, sourceBundleId: presentation.sourceBundleId)
        toolTip = presentation.kind == .password ? nil : "\(presentation.title)\n\(presentation.subtitle)"
        setAccessibilityLabel(presentation.accessibilityLabel)
        rebuildActions(kind: presentation.kind, isFavorite: isFavorite, tab: isPassword ? .passwords : tab)
        updateActionVisibility()
    }

    /// Driven by HistoryTableRowView so unemphasized selection still reveals actions.
    func setRowSelected(_ selected: Bool) {
        isRowSelected = selected
        updateActionVisibility()
    }

    private func updateActionVisibility() {
        let visible = (isHovering || isRowSelected) && !actionButtons.isEmpty
        actionsStack.isHidden = !visible
        shortcutLabel.isHidden = visible || shortcutLabel.stringValue.isEmpty
        accessoryView.alphaValue = visible ? 0 : 1
        // Deactivate first so the two trailing bounds never coexist.
        NSLayoutConstraint.deactivate(visible ? textToAccessory : textToActions)
        NSLayoutConstraint.activate(visible ? textToActions : textToAccessory)
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            let emphasized = backgroundStyle == .emphasized
            titleLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .labelColor
            subtitleLabel.textColor = emphasized
                ? NSColor.alternateSelectedControlTextColor.withAlphaComponent(0.8)
                : .secondaryLabelColor
            shortcutLabel.textColor = emphasized
                ? NSColor.alternateSelectedControlTextColor.withAlphaComponent(0.8)
                : .tertiaryLabelColor
            let tint: NSColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
            actionButtons.values.forEach { $0.contentTintColor = tint }
            accessoryView.contentTintColor = emphasized ? .alternateSelectedControlTextColor : .systemYellow
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        (superview as? HistoryTableRowView)?.isHovered = true
        updateActionVisibility()
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        (superview as? HistoryTableRowView)?.isHovered = false
        updateActionVisibility()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isHovering = false
        isRowSelected = false
        onAction = nil
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

    private func rebuildActions(kind: ItemKind, isFavorite: Bool, tab: HistoryListMode) {
        actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        for spec in RowActionOverlay.buttons(kind: kind, isFavorite: isFavorite, tab: tab) {
            let image = NSImage(systemSymbolName: spec.symbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(config) ?? NSImage()
            let button = NSButton(image: image, target: self, action: #selector(actionClicked(_:)))
            button.bezelStyle = .inline
            button.isBordered = false
            button.imagePosition = .imageOnly
            button.contentTintColor = backgroundStyle == .emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
            button.toolTip = RowActionOverlay.tooltip(for: spec)
            button.identifier = NSUserInterfaceItemIdentifier(spec.id.rawValue)
            button.setAccessibilityElement(false)
            button.refusesFirstResponder = true
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 24).isActive = true
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            actionsStack.addArrangedSubview(button)
            actionButtons[spec.id] = button
        }
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

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.textColor = .tertiaryLabelColor
        shortcutLabel.alignment = .right
        shortcutLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        shortcutLabel.setContentHuggingPriority(.required, for: .horizontal)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.contentTintColor = .systemYellow

        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.orientation = .horizontal
        actionsStack.spacing = 0
        actionsStack.isHidden = true
        actionsStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        [leadingView, titleLabel, subtitleLabel, shortcutLabel, accessoryView, actionsStack].forEach(addSubview)

        let pad = PanelTheme.Spacing.sm + 2
        // Title and subtitle each bound independently; tying subtitle.trailing to the title
        // made Auto Layout split the width between them and truncate both early.
        textToAccessory = [titleLabel, subtitleLabel].map {
            $0.trailingAnchor.constraint(lessThanOrEqualTo: accessoryView.leadingAnchor, constant: -6)
        }
        textToActions = [titleLabel, subtitleLabel].map {
            $0.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -6)
        }

        NSLayoutConstraint.activate([
            leadingView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            leadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingView.widthAnchor.constraint(equalToConstant: RowArtworkProvider.side),
            leadingView.heightAnchor.constraint(equalToConstant: RowArtworkProvider.side),

            titleLabel.leadingAnchor.constraint(equalTo: leadingView.trailingAnchor, constant: PanelTheme.Spacing.sm + 2),
            titleLabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: 1),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 1),

            shortcutLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            shortcutLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            accessoryView.trailingAnchor.constraint(equalTo: shortcutLabel.leadingAnchor, constant: -6),
            accessoryView.centerYAnchor.constraint(equalTo: centerYAnchor),
            accessoryView.widthAnchor.constraint(equalToConstant: 12),
            accessoryView.heightAnchor.constraint(equalToConstant: 12),

            actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(pad - 4)),
            actionsStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ] + textToAccessory)
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
            return NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
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

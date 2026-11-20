//
// HistoryRowView — single compact row: leading art, title/subtitle, shortcut (U11).
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
        isPassword: Bool
    ) {
        titleLabel.stringValue = presentation.title
        subtitleLabel.stringValue = presentation.subtitle
        titleLabel.font = PanelTheme.titleFont(for: textSize)
        subtitleLabel.font = PanelTheme.subtitleFont(for: textSize)
        shortcutLabel.font = PanelTheme.shortcutFont(for: textSize)
        if let n = shortcutNumber {
            shortcutLabel.stringValue = n == 0 ? "⌘0" : "⌘\(n)"
            shortcutLabel.isHidden = false
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
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            let emphasized = backgroundStyle == .emphasized
            titleLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .labelColor
            subtitleLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
            shortcutLabel.textColor = emphasized ? .alternateSelectedControlTextColor : .tertiaryLabelColor
        }
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

        addSubview(leadingView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(shortcutLabel)
        addSubview(accessoryView)

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
            accessoryView.heightAnchor.constraint(equalToConstant: 12)
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

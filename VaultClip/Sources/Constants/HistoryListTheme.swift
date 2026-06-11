//
//  HistoryListTheme.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

struct HistoryListTheme {
    
    struct metrics {
        /// Global scale for history / favorites / passwords panel content.
        /// Cumulative scale: 0.9 × 0.95 (10% + 5% reduction from design baseline).
        static let contentScale: CGFloat = 0.855
        
        static func scaled(_ value: CGFloat) -> CGFloat {
            (value * contentScale).rounded(.toNearestOrAwayFromZero)
        }
        
        static func scaledInsets(_ insets: NSEdgeInsets) -> NSEdgeInsets {
            NSEdgeInsets(
                top: scaled(insets.top),
                left: scaled(insets.left),
                bottom: scaled(insets.bottom),
                right: scaled(insets.right)
            )
        }
        
        static func scaledSize(_ size: NSSize) -> NSSize {
            NSSize(width: scaled(size.width), height: scaled(size.height))
        }
        
        static let rowOuterRadius: CGFloat = scaled(10)
        static let cardRadius: CGFloat = scaled(8)
        static let cardBorderWidth: CGFloat = 1
        static let selectedCardBorderWidth: CGFloat = 1.5
        
        static let rowHorizontalInset: CGFloat = scaled(12)
        static let rowVerticalSpacing: CGFloat = scaled(6)
        
        /// Horizontal padding for list, tabs, and chrome inside the history panel.
        static let panelContentInset: CGFloat = scaled(12)
        
        static let cardInsets = scaledInsets(NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        static let textPadding = scaledInsets(NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        
        static let sourceAppIconSize: CGFloat = scaled(20)
        static let sourceAppIconTrailingInset: CGFloat = scaled(10)
        static let sourceAppIconSpacing: CGFloat = scaled(8)
        static let sourceAppIconCornerRadius: CGFloat = scaled(5)
        
        static let tabBarHeight: CGFloat = scaled(36)
        static let tabCornerRadius: CGFloat = scaled(8)
        static let tabIconSize: CGFloat = scaled(14)
        static let tabIconSpacing: CGFloat = scaled(5)
        static let tabContentInset: CGFloat = scaled(10)
        
        static let shortcutCornerRadius: CGFloat = scaled(6)
        static let shortcutTextInset = NSSize(
            width: scaled(6),
            height: scaled(3)
        )
        
        /// Space below the window top edge to the title (panel is laid out in visibleFrame, below the menu bar).
        static let headerTopInset: CGFloat = scaled(14)
        static let searchBarHeight: CGFloat = scaled(28)
        static let titleToSearchSpacing: CGFloat = scaled(8)
        static let searchToTabsSpacing: CGFloat = scaled(15)
        static let tabsToListSpacing: CGFloat = scaled(8)
        static let titleFontSize: CGFloat = scaled(15)
        
        static let fileTypeIconSize = scaledSize(NSSize(width: 32, height: 32))
        static let fileTypeIconPadding = scaledInsets(NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        static let fileTypeTextInset = scaledInsets(NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        
        static let imageCellPadding = scaledInsets(NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6))
        static let thumbnailPreviewSize = scaledSize(NSSize(width: 300, height: 200))
        static let thumbnailTopPadding: CGFloat = scaled(5)
        static let thumbnailFileNamePadding = scaledInsets(NSEdgeInsets(top: 10, left: 5, bottom: 10, right: 5))
        
        static let maxCellHeight: CGFloat = scaled(200)
        static let imageCellMinHeight: CGFloat = scaled(50)
        
        static func listTextContainerWidth(cellWidth: CGFloat, textPadding: NSEdgeInsets) -> CGFloat {
            let chrome = textPadding.left + textPadding.right
                + cardInsets.left + cardInsets.right
                + sourceAppIconSize + sourceAppIconSpacing + sourceAppIconTrailingInset
            return max(0, cellWidth - chrome)
        }
    }
    
    struct colors {
        
        static var accent: NSColor {
            if #available(macOS 10.14, *) {
                return .controlAccentColor
            }
            return .systemBlue
        }
        
        static func rowOuterFill(isSelected: Bool, isHovered: Bool) -> NSColor {
            if isSelected {
                return accent.withAlphaComponent(0.20)
            }
            if isHovered {
                return accent.withAlphaComponent(0.07)
            }
            return .clear
        }
        
        static func cardBorder(isSelected: Bool) -> NSColor {
            if isSelected {
                return accent.withAlphaComponent(0.75)
            }
            return NSColor.separatorColor.withAlphaComponent(0.45)
        }
        
        static var sourceIconBackdrop: NSColor {
            NSColor.separatorColor.withAlphaComponent(0.22)
        }
        
        static var shortcutBackgroundSelected: NSColor {
            NSColor(named: NSColor.Name("TextBackgroundColor")) ?? .controlBackgroundColor
        }
        
        static var shortcutForegroundNormal: NSColor {
            .white.withAlphaComponent(0.92)
        }
        
        static var shortcutForegroundSelected: NSColor {
            accent
        }
        
        static var copiedAtLabel: NSColor {
            .secondaryLabelColor
        }
        
        static var passwordCommentLabel: NSColor {
            .labelColor
        }
        
        static var passwordLoginLabel: NSColor {
            .secondaryLabelColor
        }
    }
    
    struct typography {
        
        static let bodySize: CGFloat = metrics.scaled(12)
        static let chromeSize: CGFloat = metrics.scaled(13)
        static let countSize: CGFloat = metrics.scaled(11)
        static let tabSize: CGFloat = metrics.scaled(12)
        
        static var body: NSFont {
            if #available(OSX 10.15, *) {
                return NSFont(name: "SF Mono Regular", size: bodySize)
                    ?? NSFont.monospacedSystemFont(ofSize: bodySize, weight: .regular)
            }
            return NSFont(name: "Roboto Mono Light for Powerline", size: bodySize)
                ?? NSFont.systemFont(ofSize: bodySize)
        }
        
        static var bodyParagraphStyle: NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = metrics.scaled(2)
            style.alignment = .left
            return style
        }
        
        static var leftAlignedAttributes: [NSAttributedString.Key: Any] {
            [.paragraphStyle: bodyParagraphStyle]
        }
    }
}

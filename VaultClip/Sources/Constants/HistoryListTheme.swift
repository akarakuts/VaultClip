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
        static let rowOuterRadius: CGFloat = 10
        static let cardRadius: CGFloat = 8
        static let cardBorderWidth: CGFloat = 1
        static let selectedCardBorderWidth: CGFloat = 1.5
        
        static let rowHorizontalInset: CGFloat = 12
        static let rowVerticalSpacing: CGFloat = 6
        
        static let cardInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        static let textPadding = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        
        static let sourceAppIconSize: CGFloat = 20
        static let sourceAppIconTrailingInset: CGFloat = 10
        static let sourceAppIconSpacing: CGFloat = 8
        static let sourceAppIconCornerRadius: CGFloat = 5
        
        static let tabBarHeight: CGFloat = 36
        static let tabCornerRadius: CGFloat = 8
        static let tabIconSize: CGFloat = 14
        static let tabIconSpacing: CGFloat = 5
        static let tabContentInset: CGFloat = 10
        
        static let shortcutCornerRadius: CGFloat = 6
        static let shortcutTextInset = NSSize(width: 6, height: 3)
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
            .secondaryLabelColor
        }
    }
    
    struct typography {
        
        static let bodySize: CGFloat = 12
        static let chromeSize: CGFloat = 13
        static let countSize: CGFloat = 11
        static let tabSize: CGFloat = 12
        
        static var body: NSFont {
            Constants.fonts.listPlainText
        }
        
        static var bodyParagraphStyle: NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 2
            style.alignment = .left
            return style
        }
        
        static var leftAlignedAttributes: [NSAttributedString.Key: Any] {
            [.paragraphStyle: bodyParagraphStyle]
        }
    }
}

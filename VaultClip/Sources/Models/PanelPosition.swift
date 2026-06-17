//
//  PanelPosition.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

enum PanelPosition: Int, Codable, CaseIterable {
    case right = 0
    case left = 1
    case top = 2
    case bottom = 3
    case centerExtraSmall = 8
    case centerSmall = 4
    case centerMedium = 5
    case centerLarge = 6
    case fullScreen = 7
    
    public func getFrame(forScreen screen: NSScreen) -> NSRect {
        // visibleFrame excludes the menu bar and Dock so panel chrome stays on screen.
        let visible = screen.visibleFrame
        switch self {
        case .right:
            return NSRect(
                x: screen.frame.maxX - Constants.panel.menuWidth,
                y: visible.minY,
                width: Constants.panel.menuWidth,
                height: visible.height
            )
        case .left:
            return NSRect(
                x: screen.frame.minX,
                y: visible.minY,
                width: Constants.panel.menuWidth,
                height: visible.height
            )
        case .top:
            return NSRect(
                x: visible.minX,
                y: visible.maxY - Constants.panel.menuHeight,
                width: visible.width,
                height: Constants.panel.menuHeight
            )
        case .bottom:
            return NSRect(
                x: visible.minX,
                y: visible.minY,
                width: visible.width,
                height: Constants.panel.menuHeight
            )
        case .centerExtraSmall:
            let size = NSSize(width: visible.width / 3, height: visible.height / 3)
            return Self.centerRect(ofSize: size, inRect: visible)
        case .centerSmall:
            let size = NSSize(width: visible.width / 2, height: visible.height / 2)
            return Self.centerRect(ofSize: size, inRect: visible)
        case .centerMedium:
            let size = NSSize(width: visible.width * 0.7, height: visible.height * 0.7)
            return Self.centerRect(ofSize: size, inRect: visible)
        case .centerLarge:
            let size = NSSize(width: visible.width * 0.85, height: visible.height * 0.85)
            return Self.centerRect(ofSize: size, inRect: visible)
        case .fullScreen:
            return visible
        }
    }
    
    private static func centerRect(ofSize size: NSSize, inRect rect: NSRect) -> NSRect {
        return NSRect(origin: NSPoint(x: (rect.width - size.width) / 2 + rect.minX, y: (rect.height - size.height) / 2 + rect.minY), size: size)
    }
    
    var title: String {
        switch self {
        case .right:
            return L10n.positionRight
        case .left:
            return L10n.positionLeft
        case .top:
            return L10n.positionTop
        case .bottom:
            return L10n.positionBottom
        case .centerExtraSmall:
            return L10n.positionCenterExtraSmall
        case .centerSmall:
            return L10n.positionCenterSmall
        case .centerMedium:
            return L10n.positionCenterMedium
        case .centerLarge:
            return L10n.positionCenterLarge
        case .fullScreen:
            return L10n.positionFullScreen
        }
    }
    
    var identifier: String {
        switch self {
        case .right:
            return Accessibility.identifiers.positionRightButton
        case .left:
            return Accessibility.identifiers.positionLeftButton
        case .top:
            return Accessibility.identifiers.positionTopButton
        case .bottom:
            return Accessibility.identifiers.positionBottomButton
        case.centerExtraSmall:
            return Accessibility.identifiers.positionCenterExtraSmall
        case .centerSmall:
            return Accessibility.identifiers.positionCenterSmall
        case .centerMedium:
            return Accessibility.identifiers.positionCenterMedium
        case .centerLarge:
            return Accessibility.identifiers.positionCenterLarge
        case .fullScreen:
            return Accessibility.identifiers.positionFullScreen
        }
    }
}

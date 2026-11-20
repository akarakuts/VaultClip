//
// PanelPosition — panel docking; center sizes live in Settings (U07).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

enum PanelPosition: Int, Codable, CaseIterable {
    case right = 0
    case left = 1
    case top = 2
    case bottom = 3
    case fullScreen = 7
    case center = 9

    func getFrame(forScreen screen: NSScreen, sizes: PanelSizeState = .default) -> NSRect {
        let visible = screen.visibleFrame
        return PanelFrameCalculator.frame(
            position: self,
            visible: visible,
            screenFrame: screen.frame,
            sizes: sizes
        )
    }

    /// Backwards-compatible overload used by UI tests and call sites without sizes.
    func getFrame(forScreen screen: NSScreen) -> NSRect {
        getFrame(forScreen: screen, sizes: .default)
    }

    var title: String {
        switch self {
        case .right: return L10n.positionRight
        case .left: return L10n.positionLeft
        case .top: return L10n.positionTop
        case .bottom: return L10n.positionBottom
        case .center: return L10n.positionCenter
        case .fullScreen: return L10n.positionFullScreen
        }
    }

    var symbolName: String {
        switch self {
        case .left: return "rectangle.lefthalf.inset.filled"
        case .right: return "rectangle.righthalf.inset.filled"
        case .top: return "rectangle.tophalf.inset.filled"
        case .bottom: return "rectangle.bottomhalf.inset.filled"
        case .center: return "rectangle.center.inset.filled"
        case .fullScreen: return "rectangle.inset.filled"
        }
    }

    var identifier: String {
        switch self {
        case .right: return Accessibility.identifiers.positionRightButton
        case .left: return Accessibility.identifiers.positionLeftButton
        case .top: return Accessibility.identifiers.positionTopButton
        case .bottom: return Accessibility.identifiers.positionBottomButton
        case .center: return Accessibility.identifiers.positionCenter
        case .fullScreen: return Accessibility.identifiers.positionFullScreen
        }
    }
}

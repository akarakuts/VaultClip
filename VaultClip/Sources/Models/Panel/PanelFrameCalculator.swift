//
// PanelFrameCalculator — pure panel frame geometry and size clamps (U07).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

struct PanelSizeState: Equatable {
    var edgeWidth: CGFloat
    var edgeHeight: CGFloat
    var centerWidth: CGFloat
    var centerHeight: CGFloat

    static let `default` = PanelSizeState(
        edgeWidth: 480,
        edgeHeight: 360,
        centerWidth: 0, // 0 → 60% of visible
        centerHeight: 0
    )
}

enum PanelFrameCalculator {
    static let minEdgeWidth: CGFloat = 360
    static let maxEdgeWidthCap: CGFloat = 1000
    static let minEdgeHeight: CGFloat = 260
    static let minCenterWidth: CGFloat = 640
    static let minCenterHeight: CGFloat = 420

    static func clampedEdgeWidth(_ width: CGFloat, visibleWidth: CGFloat) -> CGFloat {
        let maxW = min(visibleWidth * 0.6, maxEdgeWidthCap)
        return min(max(width, minEdgeWidth), maxW)
    }

    static func clampedEdgeHeight(_ height: CGFloat, visibleHeight: CGFloat) -> CGFloat {
        let maxH = visibleHeight * 0.7
        return min(max(height, minEdgeHeight), maxH)
    }

    static func clampedCenterSize(_ size: CGSize, visible: CGSize) -> CGSize {
        let width: CGFloat
        if size.width < 0 {
            width = visible.width * abs(size.width)
        } else if size.width > 0 {
            width = size.width
        } else {
            width = visible.width * 0.6
        }
        let height: CGFloat
        if size.height < 0 {
            height = visible.height * abs(size.height)
        } else if size.height > 0 {
            height = size.height
        } else {
            height = visible.height * 0.6
        }
        return CGSize(
            width: min(max(width, min(minCenterWidth, visible.width)), visible.width),
            height: min(max(height, min(minCenterHeight, visible.height)), visible.height)
        )
    }

    static func frame(
        position: PanelPosition,
        visible: CGRect,
        screenFrame: CGRect,
        sizes: PanelSizeState = .default
    ) -> CGRect {
        switch position {
        case .right:
            let w = clampedEdgeWidth(sizes.edgeWidth, visibleWidth: visible.width)
            return CGRect(x: screenFrame.maxX - w, y: visible.minY, width: w, height: visible.height)
        case .left:
            let w = clampedEdgeWidth(sizes.edgeWidth, visibleWidth: visible.width)
            return CGRect(x: screenFrame.minX, y: visible.minY, width: w, height: visible.height)
        case .top:
            let h = clampedEdgeHeight(sizes.edgeHeight, visibleHeight: visible.height)
            return CGRect(x: visible.minX, y: visible.maxY - h, width: visible.width, height: h)
        case .bottom:
            let h = clampedEdgeHeight(sizes.edgeHeight, visibleHeight: visible.height)
            return CGRect(x: visible.minX, y: visible.minY, width: visible.width, height: h)
        case .center:
            let size = clampedCenterSize(
                CGSize(width: sizes.centerWidth, height: sizes.centerHeight),
                visible: visible.size
            )
            return CGRect(
                x: visible.minX + (visible.width - size.width) / 2,
                y: visible.minY + (visible.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
        case .fullScreen:
            return visible
        }
    }

    /// Legacy center raw values 8/4/5/6 → center with fraction of the visible frame.
    static func migrateLegacyPosition(rawValue: Int) -> (PanelPosition, CGFloat?) {
        switch rawValue {
        case 8: return (.center, 1.0 / 3.0)
        case 4: return (.center, 0.5)
        case 5: return (.center, 0.7)
        case 6: return (.center, 0.85)
        default:
            if let position = PanelPosition(rawValue: rawValue) {
                return (position, nil)
            }
            return (.right, nil)
        }
    }
}

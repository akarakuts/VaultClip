//
// PreviewLayout — pure split geometry for embedded preview (U21).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

enum PreviewSplitAxis: Equatable {
    case horizontal // preview beside list
    case vertical   // preview below list
}

struct PreviewLayoutInput: Equatable {
    var panelWidth: CGFloat
    var panelHeight: CGFloat
    var position: PanelPosition
    var previewVisible: Bool
    /// Fraction of the primary axis for the list (0…1). Nil → defaults.
    var listFraction: CGFloat?
}

struct PreviewLayoutResult: Equatable {
    var axis: PreviewSplitAxis
    var listSize: CGFloat
    var previewSize: CGFloat
    var listFraction: CGFloat
}

enum PreviewLayout {
    static let sideBySideWidthThreshold: CGFloat = 720
    static let minListWidth: CGFloat = 320
    static let minPreviewWidth: CGFloat = 280
    static let minListHeight: CGFloat = 200
    static let minPreviewHeight: CGFloat = 160
    static let defaultSideListFraction: CGFloat = 0.45
    static let defaultBottomPreviewFraction: CGFloat = 0.40

    static func layout(_ input: PreviewLayoutInput) -> PreviewLayoutResult? {
        guard input.previewVisible else { return nil }

        let forceSide = isTopOrBottom(input.position)
        let sideBySide = forceSide || input.panelWidth >= sideBySideWidthThreshold

        if sideBySide {
            let fraction = clampedFraction(
                input.listFraction ?? defaultSideListFraction,
                total: input.panelWidth,
                minPrimary: minListWidth,
                minSecondary: minPreviewWidth
            )
            let list = input.panelWidth * fraction
            return PreviewLayoutResult(
                axis: .horizontal,
                listSize: list,
                previewSize: input.panelWidth - list,
                listFraction: fraction
            )
        }

        let previewFraction = input.listFraction.map { 1 - $0 } ?? defaultBottomPreviewFraction
        let listFraction = 1 - previewFraction
        let fraction = clampedFraction(
            listFraction,
            total: input.panelHeight,
            minPrimary: minListHeight,
            minSecondary: minPreviewHeight
        )
        let list = input.panelHeight * fraction
        return PreviewLayoutResult(
            axis: .vertical,
            listSize: list,
            previewSize: input.panelHeight - list,
            listFraction: fraction
        )
    }

    private static func isTopOrBottom(_ position: PanelPosition) -> Bool {
        switch position {
        case .top, .bottom: return true
        default: return false
        }
    }

    private static func clampedFraction(
        _ desired: CGFloat,
        total: CGFloat,
        minPrimary: CGFloat,
        minSecondary: CGFloat
    ) -> CGFloat {
        guard total > 0 else { return desired }
        let minF = minPrimary / total
        let maxF = 1 - (minSecondary / total)
        if minF > maxF {
            // Panel too small for both minima — bias to list.
            return min(1, max(0, minF))
        }
        return min(max(desired, minF), maxF)
    }
}

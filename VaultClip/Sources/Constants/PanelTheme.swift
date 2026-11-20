//
// PanelTheme — design tokens for the history panel (spacing, type, materials, motion) (U02).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

enum TextSizePreference: String, Codable, CaseIterable {
    case s
    case m
    case l
    case xl
}

enum PanelTheme {

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let panelInset: CGFloat = md
        static let controlGap: CGFloat = sm
    }

    // MARK: Radii

    enum Radius {
        static let thumbnail: CGFloat = 4
        static let centerWindow: CGFloat = 12
        static let palette: CGFloat = 10
    }

    // MARK: Hit targets

    enum HitTarget {
        static let minimum: CGFloat = 24
        static let iconGlyph: CGFloat = 15
    }

    // MARK: Typography sizes (pt)

    struct TypeSizes {
        let title: CGFloat
        let subtitle: CGFloat
        let group: CGFloat
        let shortcut: CGFloat
    }

    static func typeSizes(for preference: TextSizePreference) -> TypeSizes {
        switch preference {
        case .s: return TypeSizes(title: 11, subtitle: 10, group: 10, shortcut: 10)
        case .m: return TypeSizes(title: 13, subtitle: 11, group: 11, shortcut: 11)
        case .l: return TypeSizes(title: 15, subtitle: 12, group: 12, shortcut: 12)
        case .xl: return TypeSizes(title: 17, subtitle: 13, group: 13, shortcut: 13)
        }
    }

    static func titleFont(for preference: TextSizePreference) -> NSFont {
        .systemFont(ofSize: typeSizes(for: preference).title, weight: .regular)
    }

    static func subtitleFont(for preference: TextSizePreference) -> NSFont {
        .systemFont(ofSize: typeSizes(for: preference).subtitle, weight: .regular)
    }

    static func groupFont(for preference: TextSizePreference) -> NSFont {
        .systemFont(ofSize: typeSizes(for: preference).group, weight: .semibold)
    }

    static func shortcutFont(for preference: TextSizePreference) -> NSFont {
        .monospacedDigitSystemFont(ofSize: typeSizes(for: preference).shortcut, weight: .regular)
    }

    // MARK: Row metrics

    /// Row height = ceil(title line + subtitle line + 2 + 2×8), never below 36.
    static func rowHeight(for preference: TextSizePreference) -> CGFloat {
        let sizes = typeSizes(for: preference)
        let titleLine = NSFont.systemFont(ofSize: sizes.title).ascender
            - NSFont.systemFont(ofSize: sizes.title).descender
        let subtitleLine = NSFont.systemFont(ofSize: sizes.subtitle).ascender
            - NSFont.systemFont(ofSize: sizes.subtitle).descender
        let raw = ceil(titleLine + subtitleLine + 2 + 2 * Spacing.sm)
        return max(36, raw)
    }

    static func groupHeaderHeight(for preference: TextSizePreference) -> CGFloat {
        let size = typeSizes(for: preference).group
        let line = NSFont.systemFont(ofSize: size, weight: .semibold).ascender
            - NSFont.systemFont(ofSize: size, weight: .semibold).descender
        return ceil(line + 2 * 6)
    }

    static func leadingImageSlot(for preference: TextSizePreference) -> CGFloat {
        rowHeight(for: preference) - 12
    }

    // MARK: Materials

    enum PanelMaterialKind {
        case edge
        case floating
    }

    static func visualEffectMaterial(for kind: PanelMaterialKind) -> NSVisualEffectView.Material {
        switch kind {
        case .edge: return .sidebar
        case .floating: return .popover
        }
    }

    static var visualEffectBlendingMode: NSVisualEffectView.BlendingMode { .behindWindow }
    static var visualEffectState: NSVisualEffectView.State { .active }

    static var prefersSolidBackground: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    static var solidBackgroundColor: NSColor { .windowBackgroundColor }

    // MARK: Motion

    struct MotionDurations {
        let show: TimeInterval
        let hide: TimeInterval
        let hover: TimeInterval
        let toast: TimeInterval
        let fadeOnly: TimeInterval
    }

    static func motionDurations(reduceMotion: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) -> MotionDurations {
        if reduceMotion {
            return MotionDurations(show: 0.1, hide: 0.1, hover: 0, toast: 0.1, fadeOnly: 0.1)
        }
        return MotionDurations(show: 0.16, hide: 0.12, hover: 0.08, toast: 0.2, fadeOnly: 0.1)
    }

    static var showSlideOffset: CGFloat { 16 }
}

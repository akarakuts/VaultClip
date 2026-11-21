//
// PanelChromeStyle — resolves panel window appearance and vibrancy materials per theme.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

struct PanelChromeStyle: Equatable {
    /// `nil` = inherit system appearance.
    let windowAppearanceName: String?
    let edgeMaterialRaw: Int
    let floatingMaterialRaw: Int
    let toastMaterialRaw: Int
    let overlayListMaterialRaw: Int
    let usesSolidBackground: Bool

    var windowAppearance: NSAppearance? {
        guard let windowAppearanceName else { return nil }
        return NSAppearance(named: NSAppearance.Name(rawValue: windowAppearanceName))
    }

    func material(for kind: PanelTheme.PanelMaterialKind) -> NSVisualEffectView.Material {
        let raw = kind == .edge ? edgeMaterialRaw : floatingMaterialRaw
        return NSVisualEffectView.Material(rawValue: raw) ?? .sidebar
    }

    var toastMaterial: NSVisualEffectView.Material {
        NSVisualEffectView.Material(rawValue: toastMaterialRaw) ?? .hudWindow
    }

    var overlayListMaterial: NSVisualEffectView.Material {
        NSVisualEffectView.Material(rawValue: overlayListMaterialRaw) ?? .popover
    }
}

enum PanelChromeStyleResolver {
    /// Fallback when the OS has no public Liquid Glass material (macOS 14–25).
    static let liquidGlassFallbackEdgeMaterial: NSVisualEffectView.Material = .underWindowBackground
    static let liquidGlassFallbackFloatingMaterial: NSVisualEffectView.Material = .hudWindow
    static let liquidGlassFallbackOverlayMaterial: NSVisualEffectView.Material = .hudWindow

    /// True when a dedicated public glass material exists in the linked SDK (none on current SDK).
    static var liquidGlassMaterialIsPublicOnRunningOS: Bool {
        liquidGlassPanelMaterial() != nil
    }

    static func resolve(
        appearance: PanelAppearance,
        kind _: PanelTheme.PanelMaterialKind,
        reduceTransparency: Bool,
        liquidGlassMaterialAvailable: Bool
    ) -> PanelChromeStyle {
        if reduceTransparency {
            return PanelChromeStyle(
                windowAppearanceName: windowAppearanceName(for: appearance),
                edgeMaterialRaw: NSVisualEffectView.Material.sidebar.rawValue,
                floatingMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                toastMaterialRaw: NSVisualEffectView.Material.hudWindow.rawValue,
                overlayListMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                usesSolidBackground: true
            )
        }

        let glassEdge: Int
        let glassFloating: Int
        let glassOverlay: Int
        if liquidGlassMaterialAvailable, let glass = liquidGlassPanelMaterial() {
            let raw = glass.rawValue
            glassEdge = raw
            glassFloating = raw
            glassOverlay = raw
        } else {
            glassEdge = liquidGlassFallbackEdgeMaterial.rawValue
            glassFloating = liquidGlassFallbackFloatingMaterial.rawValue
            glassOverlay = liquidGlassFallbackOverlayMaterial.rawValue
        }

        switch appearance {
        case .system:
            return PanelChromeStyle(
                windowAppearanceName: nil,
                edgeMaterialRaw: NSVisualEffectView.Material.sidebar.rawValue,
                floatingMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                toastMaterialRaw: NSVisualEffectView.Material.hudWindow.rawValue,
                overlayListMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                usesSolidBackground: false
            )
        case .light:
            return PanelChromeStyle(
                windowAppearanceName: NSAppearance.Name.aqua.rawValue,
                edgeMaterialRaw: NSVisualEffectView.Material.sidebar.rawValue,
                floatingMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                toastMaterialRaw: NSVisualEffectView.Material.hudWindow.rawValue,
                overlayListMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                usesSolidBackground: false
            )
        case .dark:
            return PanelChromeStyle(
                windowAppearanceName: NSAppearance.Name.darkAqua.rawValue,
                edgeMaterialRaw: NSVisualEffectView.Material.sidebar.rawValue,
                floatingMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                toastMaterialRaw: NSVisualEffectView.Material.hudWindow.rawValue,
                overlayListMaterialRaw: NSVisualEffectView.Material.popover.rawValue,
                usesSolidBackground: false
            )
        case .liquidGlass:
            return PanelChromeStyle(
                windowAppearanceName: nil,
                edgeMaterialRaw: glassEdge,
                floatingMaterialRaw: glassFloating,
                toastMaterialRaw: glassOverlay,
                overlayListMaterialRaw: glassOverlay,
                usesSolidBackground: false
            )
        }
    }

    static func currentStyle(kind: PanelTheme.PanelMaterialKind) -> PanelChromeStyle {
        resolve(
            appearance: SettingsPersistence.current().panelAppearance,
            kind: kind,
            reduceTransparency: PanelTheme.prefersSolidBackground,
            liquidGlassMaterialAvailable: liquidGlassMaterialIsPublicOnRunningOS
        )
    }

    private static func windowAppearanceName(for appearance: PanelAppearance) -> String? {
        switch appearance {
        case .system, .liquidGlass: return nil
        case .light: return NSAppearance.Name.aqua.rawValue
        case .dark: return NSAppearance.Name.darkAqua.rawValue
        }
    }

    /// Returns a public glass material when the SDK exposes one; otherwise `nil` → fallback path.
    private static func liquidGlassPanelMaterial() -> NSVisualEffectView.Material? {
        if #available(macOS 26.0, *) {
            // No public Liquid Glass material in the current AppKit SDK; wire here when Apple ships one.
        }
        return nil
    }
}
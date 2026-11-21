//
// PanelChromeStyleTests — theme resolution without a live panel window.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import XCTest
@testable import VaultClip

final class PanelChromeStyleTests: XCTestCase {

    private func style(
        _ appearance: PanelAppearance,
        kind: PanelTheme.PanelMaterialKind = .edge,
        reduceTransparency: Bool = false,
        liquidGlassAvailable: Bool = false
    ) -> PanelChromeStyle {
        PanelChromeStyleResolver.resolve(
            appearance: appearance,
            kind: kind,
            reduceTransparency: reduceTransparency,
            liquidGlassMaterialAvailable: liquidGlassAvailable
        )
    }

    func testSystemUsesInheritedAppearanceAndSidebar() {
        let edge = style(.system, kind: .edge)
        XCTAssertNil(edge.windowAppearanceName)
        XCTAssertEqual(edge.edgeMaterialRaw, NSVisualEffectView.Material.sidebar.rawValue)
        XCTAssertFalse(edge.usesSolidBackground)

        let floating = style(.system, kind: .floating)
        XCTAssertEqual(floating.floatingMaterialRaw, NSVisualEffectView.Material.popover.rawValue)
    }

    func testLightAndDarkForceWindowAppearance() {
        let light = style(.light)
        XCTAssertEqual(light.windowAppearanceName, NSAppearance.Name.aqua.rawValue)
        let dark = style(.dark)
        XCTAssertEqual(dark.windowAppearanceName, NSAppearance.Name.darkAqua.rawValue)
    }

    func testLiquidGlassFallbackMaterials() {
        let edge = style(.liquidGlass, kind: .edge, liquidGlassAvailable: false)
        XCTAssertEqual(
            edge.edgeMaterialRaw,
            PanelChromeStyleResolver.liquidGlassFallbackEdgeMaterial.rawValue
        )
        XCTAssertEqual(
            edge.floatingMaterialRaw,
            PanelChromeStyleResolver.liquidGlassFallbackFloatingMaterial.rawValue
        )
        XCTAssertEqual(edge.toastMaterialRaw, PanelChromeStyleResolver.liquidGlassFallbackOverlayMaterial.rawValue)
    }

    func testReduceTransparencyForcesSolidRegardlessOfTheme() {
        for appearance in PanelAppearance.allCases {
            let resolved = style(appearance, reduceTransparency: true)
            XCTAssertTrue(resolved.usesSolidBackground)
        }
    }

    func testSettingsDecodeDefaultsPanelAppearanceToSystem() throws {
        let json = Data(#"{"panelPosition":2}"#.utf8)
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.panelAppearance, .system)
    }
}
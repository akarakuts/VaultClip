//
// CommandPaletteModelTests — ranking and registry reachability (U25).
//
import XCTest
@testable import VaultClip

final class CommandPaletteModelTests: XCTestCase {
    func testPrefixRanksAboveSubsequence() {
        let prefix = CommandPaletteRanker.score(query: "pas", title: "Paste", keywords: [])!
        let sub = CommandPaletteRanker.score(query: "pse", title: "Paste", keywords: [])!
        XCTAssertGreaterThan(prefix, sub)
    }

    func testEveryPaletteCommandReachable() {
        let context = PanelCommandContext(hasSelection: true, selectionCount: 1)
        let rows = CommandPaletteBuilder.rows(context: context, query: "")
        let paletteIDs = Set(PanelCommandRegistry.all.filter(\.showsInPalette).map(\.id))
        XCTAssertEqual(Set(rows.map(\.id)), paletteIDs)
    }

    func testMultiSelectionKeepsPaste() {
        let context = PanelCommandContext(hasSelection: true, selectionCount: 3)
        let rows = CommandPaletteBuilder.rows(context: context, query: "paste")
        XCTAssertTrue(rows.contains { $0.id == .paste })
    }
}

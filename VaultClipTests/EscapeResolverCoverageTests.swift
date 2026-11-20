//
// EscapeResolverCoverageTests — full Esc stack matrix (U04).
//
import XCTest
@testable import VaultClip

final class EscapeResolverCoverageTests: XCTestCase {
    func testLayerPriority() {
        var state = EscapeStackState()
        XCTAssertEqual(EscapeResolver.resolve(state), .closePanel)
        state.filtersActive = true
        XCTAssertEqual(EscapeResolver.resolve(state), .clearFilters)
        state.searchIsEmpty = false
        XCTAssertEqual(EscapeResolver.resolve(state), .clearSearch)
        state.multiSelectActive = true
        XCTAssertEqual(EscapeResolver.resolve(state), .collapseMultiSelect)
        state.passwordRevealed = true
        XCTAssertEqual(EscapeResolver.resolve(state), .hidePassword)
        state.editorActive = true
        state.editorHasChanges = true
        XCTAssertEqual(EscapeResolver.resolve(state), .warnEditorDiscard)
        state.editorDiscardArmed = true
        XCTAssertEqual(EscapeResolver.resolve(state), .leaveEditor)
        state.overlayVisible = true
        XCTAssertEqual(EscapeResolver.resolve(state), .dismissOverlay)
    }

    func testActiveLayersOrdering() {
        let state = EscapeStackState(
            overlayVisible: true,
            editorActive: true,
            editorHasChanges: true,
            editorDiscardArmed: false,
            passwordRevealed: true,
            multiSelectActive: true,
            searchIsEmpty: false,
            filtersActive: true
        )
        let layers = EscapeResolver.activeLayers(state)
        XCTAssertEqual(layers.first, .overlay)
        XCTAssertEqual(layers.last, .panel)
        XCTAssertTrue(layers.contains(.editorDirtyConfirm))
        XCTAssertLessThan(EscapeLayer.overlay, EscapeLayer.panel)
    }
}

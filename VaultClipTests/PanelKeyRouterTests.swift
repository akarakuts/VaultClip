//
// PanelKeyRouterTests — zone × chord routing, type-to-search, Esc stack (U04).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class PanelKeyRouterTests: XCTestCase {

    func testListArrowRoutesToSelection() {
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .list, chord: KeyChord(key: .downArrow, modifiers: [])),
            .command(.selectNext)
        )
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .list, chord: KeyChord(key: .upArrow, modifiers: [])),
            .command(.selectPrevious)
        )
    }

    func testTypeToSearchFromList() {
        let route = PanelKeyRouter.route(
            zone: .list,
            chord: KeyChord(key: .letter("s"), modifiers: []),
            typed: "s"
        )
        XCTAssertEqual(route, .typeToSearch("s"))
    }

    func testSpaceInSearchPassesThroughWhileListTogglesPreview() {
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .search, chord: KeyChord(key: .space, modifiers: [])),
            .passThrough
        )
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .list, chord: KeyChord(key: .space, modifiers: [])),
            .command(.togglePreview)
        )
    }

    func testCommandDeleteInSearchDependsOnEmptiness() {
        let delete = KeyChord(key: .delete, modifiers: .command)
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .search, chord: delete, context: .init(searchIsEmpty: false)),
            .passThrough
        )
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .search, chord: delete, context: .init(searchIsEmpty: true)),
            .command(.delete)
        )
    }

    func testCommandAInSearch() {
        let chord = KeyChord.cmd("a")
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .search, chord: chord, context: .init(searchIsEmpty: false)),
            .passThrough
        )
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .search, chord: chord, context: .init(searchIsEmpty: true)),
            .command(.selectAll)
        )
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .list, chord: chord),
            .command(.selectAll)
        )
    }

    func testEscapeStackOrder() {
        var state = EscapeStackState(
            overlayVisible: true,
            editorActive: true,
            editorHasChanges: true,
            passwordRevealed: true,
            multiSelectActive: true,
            searchIsEmpty: false,
            filtersActive: true
        )
        XCTAssertEqual(EscapeResolver.resolve(state), .dismissOverlay)

        state.overlayVisible = false
        XCTAssertEqual(EscapeResolver.resolve(state), .warnEditorDiscard)

        state.editorDiscardArmed = true
        XCTAssertEqual(EscapeResolver.resolve(state), .leaveEditor)

        state.editorActive = false
        XCTAssertEqual(EscapeResolver.resolve(state), .hidePassword)

        state.passwordRevealed = false
        XCTAssertEqual(EscapeResolver.resolve(state), .collapseMultiSelect)

        state.multiSelectActive = false
        XCTAssertEqual(EscapeResolver.resolve(state), .clearSearch)

        state.searchIsEmpty = true
        XCTAssertEqual(EscapeResolver.resolve(state), .clearFilters)

        state.filtersActive = false
        XCTAssertEqual(EscapeResolver.resolve(state), .closePanel)
    }

    func testCommandWClosesPanel() {
        XCTAssertEqual(
            PanelKeyRouter.route(zone: .list, chord: .cmd("w")),
            .command(.closePanel)
        )
    }
}

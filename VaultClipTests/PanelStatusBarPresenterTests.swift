//
// PanelStatusBarPresenterTests — counter plurals and hint trimming (U09); copy via L10n.
//
import XCTest
@testable import VaultClip

final class PanelStatusBarPresenterTests: XCTestCase {
    func testCounterUsesCatalog() {
        let base = PanelStatusBarInput(
            totalCount: 128, visibleCount: 128, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: .current
        )
        XCTAssertEqual(PanelStatusBarPresenter.counter(for: base), L10n.countItems(128))
        var search = base
        search.isSearch = true
        search.visibleCount = 12
        XCTAssertEqual(
            PanelStatusBarPresenter.counter(for: search),
            L10n.statusFoundOf(visible: 12, total: 128)
        )
        var multi = base
        multi.selectedCount = 4
        XCTAssertEqual(PanelStatusBarPresenter.counter(for: multi), L10n.statusSelected(4))
    }

    func testHintsTrimByWidth() {
        let wide = PanelStatusBarInput(
            totalCount: 1, visibleCount: 1, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: .current
        )
        let hints = PanelStatusBarPresenter.hints(for: wide)
        XCTAssertEqual(hints.count, 3)
        XCTAssertEqual(hints.first, L10n.hintPaste)
        var narrow = wide
        narrow.availableWidth = 100
        XCTAssertEqual(PanelStatusBarPresenter.hints(for: narrow).count, 1)
        XCTAssertEqual(PanelStatusBarPresenter.hints(for: narrow).first, L10n.hintPaste)
        narrow.showKeyHints = false
        XCTAssertTrue(PanelStatusBarPresenter.hints(for: narrow).isEmpty)
    }

    func testCounterAppendsFilterSummary() {
        var input = PanelStatusBarInput(
            totalCount: 10, visibleCount: 3, isSearch: true, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: .current, filterSummary: "Text · Safari"
        )
        let text = PanelStatusBarPresenter.counter(for: input)
        XCTAssertTrue(text.hasSuffix(" · Text · Safari"))
        XCTAssertTrue(text.contains(L10n.statusFoundOf(visible: 3, total: 10)))
        input.filterSummary = nil
        XCTAssertEqual(
            PanelStatusBarPresenter.counter(for: input),
            L10n.statusFoundOf(visible: 3, total: 10)
        )
    }

    func testListHintsDocumentClickPolicy() {
        let input = PanelStatusBarInput(
            totalCount: 1, visibleCount: 1, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 500, showKeyHints: true,
            locale: .current, filterSummary: "Text"
        )
        let hints = PanelStatusBarPresenter.hints(for: input)
        XCTAssertEqual(hints.count, 3)
        XCTAssertEqual(hints[0], L10n.hintPaste)
        XCTAssertEqual(hints[1], L10n.hintDoubleClickPaste)
    }

    func testMultiSelectHintsIncludeOrder() {
        let input = PanelStatusBarInput(
            totalCount: 5, visibleCount: 5, isSearch: false, selectedCount: 3,
            isLoading: false, hintContext: .multiSelect(count: 3), availableWidth: 500,
            showKeyHints: true, locale: .current
        )
        let hints = PanelStatusBarPresenter.hints(for: input)
        XCTAssertEqual(hints.first, L10n.hintPasteCount(3))
        XCTAssertTrue(hints.contains(L10n.hintMultiPasteOrder))
    }
}

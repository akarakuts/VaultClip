//
// PanelStatusBarPresenterTests — counter plurals and hint trimming (U09).
//
import XCTest
@testable import VaultClip

final class PanelStatusBarPresenterTests: XCTestCase {
    func testCounterPluralsEnRu() {
        let en = PanelStatusBarInput(
            totalCount: 128, visibleCount: 128, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(PanelStatusBarPresenter.counter(for: en), "128 items")
        let ru = PanelStatusBarInput(
            totalCount: 128, visibleCount: 128, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: Locale(identifier: "ru_RU")
        )
        XCTAssertEqual(PanelStatusBarPresenter.counter(for: ru), "128 элементов")
        var search = en
        search.isSearch = true
        search.visibleCount = 12
        XCTAssertEqual(PanelStatusBarPresenter.counter(for: search), "Found 12 of 128")
    }

    func testHintsTrimByWidth() {
        let wide = PanelStatusBarInput(
            totalCount: 1, visibleCount: 1, isSearch: false, selectedCount: 0,
            isLoading: false, hintContext: .list, availableWidth: 400, showKeyHints: true,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(PanelStatusBarPresenter.hints(for: wide).count, 3)
        var narrow = wide
        narrow.availableWidth = 100
        XCTAssertEqual(PanelStatusBarPresenter.hints(for: narrow).count, 1)
        narrow.showKeyHints = false
        XCTAssertTrue(PanelStatusBarPresenter.hints(for: narrow).isEmpty)
    }
}

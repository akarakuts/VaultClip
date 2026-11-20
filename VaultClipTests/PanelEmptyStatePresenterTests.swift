//
// PanelEmptyStatePresenterTests — empty/loading combinations (U10).
//
import XCTest
@testable import VaultClip

final class PanelEmptyStatePresenterTests: XCTestCase {
    func testLoadingWins() {
        let model = PanelEmptyStatePresenter.present(
            kind: .history, isLoading: true, isCapturePaused: false,
            filtersActive: false, otherTabHitCount: nil, otherTab: nil,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(model?.symbolName, "arrow.triangle.2.circlepath")
    }

    func testHistoryFavoritesPasswords() {
        XCTAssertEqual(
            PanelEmptyStatePresenter.present(
                kind: .history, isLoading: false, isCapturePaused: false,
                filtersActive: false, otherTabHitCount: nil, otherTab: nil
            )?.symbolName,
            "doc.on.clipboard"
        )
        XCTAssertEqual(
            PanelEmptyStatePresenter.present(
                kind: .favorites, isLoading: false, isCapturePaused: false,
                filtersActive: false, otherTabHitCount: nil, otherTab: nil
            )?.symbolName,
            "star"
        )
        XCTAssertEqual(
            PanelEmptyStatePresenter.present(
                kind: .passwords, isLoading: false, isCapturePaused: false,
                filtersActive: false, otherTabHitCount: nil, otherTab: nil
            )?.symbolName,
            "key"
        )
    }

    func testNoResultsOtherTab() {
        let model = PanelEmptyStatePresenter.present(
            kind: .noResults(query: "foo"),
            isLoading: false,
            isCapturePaused: false,
            filtersActive: true,
            otherTabHitCount: 3,
            otherTab: .favorites,
            locale: Locale(identifier: "ru_RU")
        )
        XCTAssertEqual(model?.primaryButtonTitle, "Перейти")
        XCTAssertTrue(model?.description.contains("Избранное") == true)
    }
}

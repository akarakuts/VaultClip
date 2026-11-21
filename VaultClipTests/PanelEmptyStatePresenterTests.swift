//
// PanelEmptyStatePresenterTests — empty/loading combinations (U10); copy via L10n catalog.
//
import XCTest
@testable import VaultClip

final class PanelEmptyStatePresenterTests: XCTestCase {
    func testLoadingWins() {
        let model = PanelEmptyStatePresenter.present(
            kind: .history, isLoading: true, isCapturePaused: false,
            filtersActive: false, otherTabHitCount: nil, otherTab: nil
        )
        XCTAssertEqual(model?.symbolName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(model?.title, L10n.historyLoading)
    }

    func testHistoryFavoritesPasswords() {
        XCTAssertEqual(
            PanelEmptyStatePresenter.present(
                kind: .history, isLoading: false, isCapturePaused: false,
                filtersActive: false, otherTabHitCount: nil, otherTab: nil
            )?.title,
            L10n.emptyHistoryTitle
        )
        XCTAssertEqual(
            PanelEmptyStatePresenter.present(
                kind: .favorites, isLoading: false, isCapturePaused: false,
                filtersActive: false, otherTabHitCount: nil, otherTab: nil
            )?.title,
            L10n.emptyFavoritesTitle
        )
        let passwords = PanelEmptyStatePresenter.present(
            kind: .passwords, isLoading: false, isCapturePaused: false,
            filtersActive: false, otherTabHitCount: nil, otherTab: nil
        )
        XCTAssertEqual(passwords?.title, L10n.emptyPasswordsTitle)
        XCTAssertTrue(passwords?.description.contains(L10n.emptyPasswordsBodyManagers) == true)
        XCTAssertTrue(passwords?.description.contains(L10n.emptyPasswordsBodySave) == true)
    }

    func testNoResultsOtherTab() {
        let model = PanelEmptyStatePresenter.present(
            kind: .noResults(query: "foo"),
            isLoading: false,
            isCapturePaused: false,
            filtersActive: true,
            otherTabHitCount: 3,
            otherTab: .favorites
        )
        XCTAssertEqual(model?.primaryButtonTitle, L10n.emptyGo)
        XCTAssertTrue(model?.description.contains(L10n.tabFavorites) == true)
        XCTAssertEqual(model?.title, L10n.emptyNoResultsTitle("foo"))
    }

    func testPausedOffersResume() {
        let model = PanelEmptyStatePresenter.present(
            kind: .history, isLoading: false, isCapturePaused: true,
            filtersActive: false, otherTabHitCount: nil, otherTab: nil
        )
        XCTAssertEqual(model?.primaryButtonTitle, L10n.emptyHistoryResume)
    }
}

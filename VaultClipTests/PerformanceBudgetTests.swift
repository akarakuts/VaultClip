//
// PerformanceBudgetTests — 5k present under CI limit (U35).
//
import XCTest
@testable import VaultClip

final class PerformanceBudgetTests: XCTestCase {
    func testPresentFiveThousand() {
        let now = Date()
        let items = PerformanceBudget.syntheticSummaries(count: 5000, now: now)
        let ids = items.indices.map { _ in UUID() }
        let ms = PerformanceBudget.measureMs {
            _ = PanelPresenter.present(PanelPresenterInput(
                items: items,
                itemIds: ids,
                tab: .history,
                searchQuery: "",
                selectedIds: [],
                groupByDay: true,
                now: now,
                calendar: Calendar(identifier: .gregorian),
                locale: Locale(identifier: "en_US")
            ))
        }
        XCTAssertLessThan(ms, PerformanceBudget.presentFilterLimitMs, "present 5k took \(ms) ms")
    }
}

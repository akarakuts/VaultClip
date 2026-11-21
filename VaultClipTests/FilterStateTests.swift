//
// FilterStateTests — type/app tokens and aggregation (U13/U14).
//
import XCTest
@testable import VaultClip

final class FilterStateTests: XCTestCase {
    func testTypeTokenSynonyms() {
        let en = SearchTokenParser.parse("type:link hello")
        XCTAssertEqual(en.filter.type, .link)
        XCTAssertEqual(en.remainingQuery, "hello")
        let ru = SearchTokenParser.parse("тип:картинка код")
        XCTAssertEqual(ru.filter.type, .image)
        XCTAssertEqual(ru.remainingQuery, "код")
    }

    func testAppTokenQuoted() {
        let result = SearchTokenParser.parse(#"app:"Google Chrome" note"#)
        XCTAssertEqual(result.filter.appQuery, "Google Chrome")
        XCTAssertEqual(result.remainingQuery, "note")
    }

    func testPartialTypeTokenStaysInQuery() {
        let result = SearchTokenParser.parse("type:lin")
        XCTAssertEqual(result.filter.type, .all)
        XCTAssertEqual(result.remainingQuery, "type:lin")
    }

    func testTypeMatchesKinds() {
        XCTAssertTrue(TypeFilter.text.matches(.richText))
        XCTAssertTrue(TypeFilter.file.matches(.pdf))
        XCTAssertTrue(TypeFilter.file.matches(.file(2)))
        XCTAssertFalse(TypeFilter.image.matches(.text))
    }

    func testAppAggregationSortedByCount() {
        let items = [
            (bundleId: "a.safari", displayName: "Safari"),
            (bundleId: "a.safari", displayName: "Safari"),
            (bundleId: "a.chrome", displayName: "Chrome"),
            (bundleId: nil, displayName: "")
        ]
        let agg = AppFilterAggregator.aggregate(items: items)
        XCTAssertEqual(agg.first?.bundleId, "a.safari")
        XCTAssertEqual(agg.last?.bundleId, nil)
    }

    func testCombinedFilters() {
        var state = FilterState(type: .text, appQuery: "safari")
        XCTAssertTrue(state.matches(kind: .text, sourceBundleId: "com.apple.Safari", appDisplayName: "Safari"))
        XCTAssertFalse(state.matches(kind: .image, sourceBundleId: "com.apple.Safari", appDisplayName: "Safari"))
        XCTAssertFalse(state.matches(kind: .text, sourceBundleId: "com.google.Chrome", appDisplayName: "Chrome"))
    }

    func testSummaryLabel() {
        XCTAssertNil(FilterState().summaryLabel)
        XCTAssertEqual(
            FilterState(type: .text, appQuery: "Safari").summaryLabel,
            "\(L10n.filterTypeText) · Safari"
        )
        XCTAssertEqual(FilterState(type: .image, appQuery: nil).summaryLabel, L10n.filterTypeImages)
    }
}

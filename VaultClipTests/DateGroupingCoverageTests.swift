//
// DateGroupingCoverageTests — raise strict coverage for DateGrouping (U12/U35).
//
import XCTest
@testable import VaultClip

final class DateGroupingCoverageTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    func testAllBucketsAndTitles() {
        let now = Date(timeIntervalSince1970: 1_700_000_000) // fixed
        let today = calendar.startOfDay(for: now)
        XCTAssertEqual(DateGrouping.bucket(for: today, now: now, calendar: calendar), .today)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        XCTAssertEqual(DateGrouping.bucket(for: yesterday, now: now, calendar: calendar), .yesterday)
        let fiveDays = calendar.date(byAdding: .day, value: -5, to: today)!
        XCTAssertEqual(DateGrouping.bucket(for: fiveDays, now: now, calendar: calendar), .last7Days)
        let twenty = calendar.date(byAdding: .day, value: -20, to: today)!
        XCTAssertEqual(DateGrouping.bucket(for: twenty, now: now, calendar: calendar), .last30Days)
        let old = calendar.date(byAdding: .day, value: -90, to: today)!
        let bucket = DateGrouping.bucket(for: old, now: now, calendar: calendar)
        if case .month = bucket { } else { XCTFail("expected month") }

        let en = Locale(identifier: "en_US")
        let ru = Locale(identifier: "ru_RU")
        XCTAssertEqual(DateGrouping.title(for: .today, now: now, calendar: calendar, locale: en), "Today")
        XCTAssertEqual(DateGrouping.title(for: .today, now: now, calendar: calendar, locale: ru), "Сегодня")
        XCTAssertEqual(DateGrouping.title(for: .yesterday, now: now, calendar: calendar, locale: en), "Yesterday")
        XCTAssertEqual(DateGrouping.title(for: .yesterday, now: now, calendar: calendar, locale: ru), "Вчера")
        XCTAssertEqual(DateGrouping.title(for: .last7Days, now: now, calendar: calendar, locale: en), "Previous 7 Days")
        XCTAssertEqual(DateGrouping.title(for: .last7Days, now: now, calendar: calendar, locale: ru), "Последние 7 дней")
        XCTAssertEqual(DateGrouping.title(for: .last30Days, now: now, calendar: calendar, locale: en), "Previous 30 Days")
        XCTAssertEqual(DateGrouping.title(for: .last30Days, now: now, calendar: calendar, locale: ru), "Последние 30 дней")
        let monthTitle = DateGrouping.title(for: .month(year: 2020, month: 1), now: now, calendar: calendar, locale: en)
        XCTAssertFalse(monthTitle.isEmpty)
        let sameYear = calendar.component(.year, from: now)
        let sameYearTitle = DateGrouping.title(for: .month(year: sameYear, month: 3), now: now, calendar: calendar, locale: en)
        XCTAssertFalse(sameYearTitle.isEmpty)
    }
}

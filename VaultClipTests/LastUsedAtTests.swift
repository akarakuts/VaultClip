//
// LastUsedAtTests — metadata exclusion, defaults, grouping, DST (U12).
//
import XCTest
@testable import VaultClip

final class LastUsedAtTests: XCTestCase {
    func testLastUsedAtIsMetadataNotPasteboardType() {
        XCTAssertTrue(HistoryItem.metadataFileNames.contains(HistoryItem.lastUsedAtMetadataFileName))
        XCTAssertTrue(HistoryItem.isMetadataFileName(HistoryItem.lastUsedAtMetadataFileName))
    }

    func testMissingLastUsedAtFallsBackToCopiedAt() {
        let cache = HistoryCache()
        let copied = Date(timeIntervalSince1970: 1_700_000_000)
        let item = HistoryItem(unsavedData: [.string: Data("x".utf8)], cache: cache, copiedAt: copied)
        XCTAssertEqual(item.lastUsedAt, copied)
    }

    func testMidnightBoundaryBuckets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = calendar.timeZone
        comps.year = 2025; comps.month = 11; comps.day = 20; comps.hour = 10
        let now = comps.date!
        comps.hour = 1
        let today = comps.date!
        comps.day = 19; comps.hour = 23
        let yesterday = comps.date!
        // Compare against the same calendar instance used for construction.
        XCTAssertTrue(calendar.isDate(today, inSameDayAs: now))
        XCTAssertEqual(DateGrouping.bucket(for: today, now: now, calendar: calendar), .today)
        XCTAssertEqual(DateGrouping.bucket(for: yesterday, now: now, calendar: calendar), .yesterday)
    }

    func testDSTFixtureAmericaNewYork() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        // Spring forward 2025-03-09
        let now = calendar.date(from: DateComponents(year: 2025, month: 3, day: 12, hour: 12))!
        let before = calendar.date(from: DateComponents(year: 2025, month: 3, day: 8, hour: 12))!
        XCTAssertEqual(DateGrouping.bucket(for: before, now: now, calendar: calendar), .last7Days)
    }

    func testRetentionUsesLastUsedAt() {
        let cache = HistoryCache()
        let old = HistoryItem(unsavedData: [.string: Data("a".utf8)], cache: cache, copiedAt: Date().addingTimeInterval(-10 * 86_400))
        old.lastUsedAt = Date()
        let ids = HistoryRetention.expiredIds(in: [old], retentionDays: 7)
        XCTAssertTrue(ids.isEmpty)
    }
}

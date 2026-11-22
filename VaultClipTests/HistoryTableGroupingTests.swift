//
// HistoryTableGroupingTests — date headers and row↔item mapping in the history table (U12).
//
import AppKit
import XCTest
@testable import VaultClip

final class HistoryTableGroupingTests: XCTestCase {
    private func items(agesInHours: [Double], now: Date) -> [HistoryItem] {
        let cache = HistoryCache()
        return agesInHours.map { hours in
            HistoryItem(unsavedData: [.string: Data("x\(hours)".utf8)], cache: cache, copiedAt: now.addingTimeInterval(-hours * 3600))
        }
    }

    func testHeadersInsertedPerBucketAndMappingRoundTrips() {
        let now = Date()
        let table = HistoryTableView(frame: .zero)
        table.historyListItems = items(agesInHours: [0, 0.5, 30, 240], now: now)
        table.groupsByDate = true
        table.rebuildDisplayRows(now: now)

        let headers = table.displayRows.filter { if case .header = $0 { return true } else { return false } }
        XCTAssertGreaterThanOrEqual(headers.count, 2)
        XCTAssertEqual(table.displayRows.count, 4 + headers.count)
        guard case .header = table.displayRows[0] else { return XCTFail("first row must be a header") }
        XCTAssertNil(table.itemIndex(forRow: 0))
        for index in 0..<4 {
            let row = try? XCTUnwrap(table.row(forItemIndex: index))
            XCTAssertEqual(row.flatMap { table.itemIndex(forRow: $0) }, index)
        }
    }

    func testUngroupedMapsOneToOne() {
        let now = Date()
        let table = HistoryTableView(frame: .zero)
        table.historyListItems = items(agesInHours: [0.0, 1, 2], now: now)
        table.groupsByDate = false
        table.rebuildDisplayRows(now: now)
        XCTAssertEqual(table.row(forItemIndex: 2), 2)
        XCTAssertEqual(table.itemIndex(forRow: 1), 1)
        XCTAssertNil(table.itemIndex(forRow: 3))
    }

    func testSelectItemsMapsThroughDateHeaders() {
        let now = Date()
        let table = HistoryTableView(frame: .zero)
        let list = items(agesInHours: [0, 0.5, 30.0], now: now)
        table.historyListItems = list
        table.groupsByDate = true
        table.rebuildDisplayRows(now: now)
        // Need a column for selectRowIndexes to stick in AppKit.
        if table.tableColumns.isEmpty {
            table.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main")))
        }
        table.reloadData()
        table.selectItems(IndexSet(integersIn: 0..<list.count))
        XCTAssertEqual(table.selectedItemIndexes.count, list.count)
        XCTAssertFalse(table.selectedRowIndexes.contains(0), "header row must stay unselected")
    }
}

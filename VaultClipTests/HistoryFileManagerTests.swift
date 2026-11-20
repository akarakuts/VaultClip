//
//  HistoryFileManagerTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

/// Tests for `HistoryFileManager`.
///
/// All depedencies are mocked out so that there is no interaction with the actual file system.
class HistoryFileManagerTests: XCTestCase {
    
    /// The actual history file manager object.
    var historyFM: HistoryFileManager!
    
    // Mocked out dependencies
    var fileManager: FileManagerMock!
    var orderManager: ArrayFileManagerMock!
    var dataFileMangaer: DataFileManagerMock!
    var dispatchQueue: DispatchQueue!
    var errorLogger: ErrorLoggerMock!
    var warningLogger: WarningLoggerMock!
    var alerter: AlerterMock!
    
    let history1: [HistoryItem] = [
        HistoryItem(fsId: UUID(), types: [], cache: HistoryCache())
    ]
    
    let history2: [HistoryItem] = [
        HistoryItem(fsId: UUID(), types: [.string], cache: HistoryCache()),
        HistoryItem(fsId: UUID(), types: [.string], cache: HistoryCache()),
        HistoryItem(fsId: UUID(), types: [.string], cache: HistoryCache())
    ]
    
    var cache = HistoryCache()
    
    
    // MARK: - Set Up
    
    override func setUp() {
        fileManager = FileManagerMock()
        orderManager = ArrayFileManagerMock(url: URL(fileURLWithPath: "test"))
        dataFileMangaer = DataFileManagerMock()
        dispatchQueue = DispatchQueue.main
        errorLogger = ErrorLoggerMock()
        warningLogger = WarningLoggerMock()
        alerter = AlerterMock()

        // CI runners have no local history files — mocks must not fall through to FileManager.default.
        fileManager.directoryContents[Constants.urls.appSupport] = [Constants.urls.history]
        fileManager.directoryContents[Constants.urls.history] = []
        fileManager.fileExists[Constants.urls.historyOrder.path] = true
        fileManager.createDirectory[Constants.urls.appSupport] = true
        fileManager.createDirectory[Constants.urls.history] = true
        
        historyFM = HistoryFileManager(
            fileManager: fileManager,
            orderManager: orderManager,
            dataFileManager: dataFileMangaer,
            dispatchQueue: dispatchQueue,
            errorLogger: errorLogger,
            warningLogger: warningLogger,
            alerter: alerter
        )
        // Order writes normally coalesce over 1 s — flush on the next queue tick in tests.
        historyFM.orderCoalesceInterval = 0
        cache = HistoryCache(historyFM: historyFM, maxCacheSize: 1_000_000)
    }

    private func makeStoredItemReadable(_ item: HistoryItem, type: NSPasteboard.PasteboardType = .string) {
        let itemUrl = historyFM.getUrl(forItemWithId: item.fsId)
        let dataUrl = historyFM.getUrl(forItemWithId: item.fsId, andPasteboardType: type)
        fileManager.directoryContents[itemUrl] = [dataUrl]
        dataFileMangaer.loadData[dataUrl] = Data("Test".utf8)
    }
    
    
    // MARK: - saveHistoryOrder()
    
    func testSaveHistoryOrderSuccess() {
        // 1. Setup mock to succeed in reading the file.
        orderManager.shouldReadSucceed = true
        orderManager.shouldWriteSucceed = true
        
        // 2. Save the history order
        let e1 = expectation(description: "Executed 1")
        let e2 = expectation(description: "Executed 2")
        historyFM.saveHistoryOrder(history: history1) { res in
            if res {
                e1.fulfill()
            }
        }
        historyFM.saveHistoryOrder(history: history2) { res in
            if res {
                e2.fulfill()
            }
        }
        
        // 3. Assert that the last history order is the history order.
        waitForExpectations(timeout: 2, handler: { _ in
            let order = self.historyFM.loadHistoryOrder()
            XCTAssertEqual(order, self.history2.map({$0.fsId}))
        })
    }
    
    func testSaveHistoryOrderFailure() {
        // 1. Setup mock to succeed in reading the file.
        orderManager.shouldWriteSucceed = false
        
        // Create expectations
        let e1 = expectation(description: "Executed 1")
        let log = expectation(description: "Error logged")
        let show = expectation(description: "Error shown")
        errorLogger.expectation = log
        alerter.expectation = show
        
        // 2. Save the history order
        historyFM.saveHistoryOrder(history: history1) { res in
            if !res {
                e1.fulfill()
            }
        }
        
        // 3. Assert that save failed, logged and showed the error
        waitForExpectations(timeout: 2)
    }
    
    // MARK: - loadHistoryOrder()
    
    func testLoadHistoryOrderSuccess() {
        // 1. Setup mock to return a valid list
        let uuidStrings = ["5FEA8AD4-390E-4988-8635-EBB08F79CDC1"]
        orderManager.order = uuidStrings as NSArray
        orderManager.shouldReadSucceed = true
        
        // 2. Get the order
        let uuids = historyFM.loadHistoryOrder()
        
        // 3. Check it is what we expect
        XCTAssertEqual(uuids!.map({$0.uuidString}), uuidStrings)
    }
    
    func testLoadHistoryOrderFailure() {
        // 1. Setup mock to return nil
        fileManager.fileExists[Constants.urls.historyOrder.path] = true
        orderManager.shouldReadSucceed = false
        
        // 2. Load the history
        let res = historyFM.loadHistoryOrder()
        
        // 3. Should be nil and logged
        XCTAssertNil(res)
        XCTAssertGreaterThan(warningLogger.loggedWarnings + errorLogger.loggedErrors, 0)
    }
    
    func testLoadHistoryOrderInvalidStrings() {
        // 1. Setup mock to return half valid list
        let uuidStrings = ["Garbage", "5FEA8AD4-390E-4988-8635-EBB08F79CDC1", "Fluff"]
        orderManager.order = uuidStrings as NSArray
        orderManager.shouldReadSucceed = true
        let warn = expectation(description: "Failure warned")
        // Should warn twice
        warn.expectedFulfillmentCount = 2
        warningLogger.expectation = warn
        
        // 2. Load the history
        let res = historyFM.loadHistoryOrder()
        
        // 3. Should have warned us twice and returned a list with a single uuid
        XCTAssertEqual(res?.count, 1)
        XCTAssertEqual(res?.first?.uuidString, uuidStrings[1])
        waitForExpectations(timeout: 1)
    }
    
    // MARK: - loadData()
    func testLoadDataWhenSuccessful() {
        // 1. Setup mock to return some data
        let testData = Data(base64Encoded: "Blah")
        let item = history2[0]
        let type = NSPasteboard.PasteboardType.string
        dataFileMangaer.loadData[historyFM.getUrl(forItemWithId: item.fsId, andPasteboardType: type)] = testData
        
        // 2. Load the data
        let data = historyFM.loadData(forItemWithId: item.fsId, andType: type)
        
        // 3. The data should be the same
        XCTAssertEqual(data, testData)
    }
    
    func testLoadDataWhenUnsuccessful() {
        // 1. Setup mock to not return some data
        let item = history2[0]
        let type = NSPasteboard.PasteboardType.string
        dataFileMangaer.loadData[historyFM.getUrl(forItemWithId: item.fsId, andPasteboardType: type)] = nil
        // There should be an error
        let err = expectation(description: "Error logged")
        errorLogger.expectation = err
        
        // 2. Load the data
        let data = historyFM.loadData(forItemWithId: item.fsId, andType: type)
        
        // 3. The data should be and an error logged
        XCTAssertNil(data)
        waitForExpectations(timeout: 1)
    }
    
    
    // MARK: - loadHistory()
    func testLoadHistoryWhenOrderNil() {
        // 1. Setup mock to return nil
        orderManager.shouldReadSucceed = false
        // Should be two logs
        let log = expectation(description: "Warning logged")
        log.assertForOverFulfill = false
        warningLogger.expectation = log
        let noItems = expectation(description: "Empty history")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. There should be an error logged
        history.subscribe(onNext: { items, _ in
            if items.count == 0 {
                noItems.fulfill()
            }
        })
        waitForExpectations(timeout: 1)
    }
    
    func testLoadHistoryWhenFailsToGetHistoryContents() {
        // 1. Setup mock to error at history contents
        orderManager.order = [UUID().uuidString] as NSArray
        orderManager.shouldReadSucceed = true
        fileManager.directoryContents[Constants.urls.history] = nil
        // Expect some errors
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        let noItems = expectation(description: "Empty history")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. There should be a history with no items
        history.subscribe(onNext: { items, _ in
            if items.count == 0 {
                noItems.fulfill()
            }
        })
        waitForExpectations(timeout: 1)
    }
    
    func testLoadHistoryWhenHistoryContentsContainsNonUUID() {
        // 1. Setup mock to have a folder in history contents with a non uuid name
        orderManager.order = history2.map({$0.fsId.uuidString}) as NSArray
        orderManager.shouldReadSucceed = true
        var contents = history2.map({historyFM.getUrl(forItemWithId: $0.fsId)})
        contents[1] = contents[1].deletingLastPathComponent().appendingPathComponent("blah blah")
        fileManager.directoryContents[Constants.urls.history] = contents
        makeStoredItemReadable(history2[0])
        makeStoredItemReadable(history2[2])
        // Expect 1 warning, 1 error
        let warn = expectation(description: "Warning logged")
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        warningLogger.expectation = warn
        errorLogger.expectation = err
        alerter.expectation = alert
        // expect 2 items
        let itemsExp = expectation(description: "History items")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. Should contain 2 items and warnings and errors should have happened
        history.subscribe { items, _ in
            if items.count == 2 {
                itemsExp.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
    
    func testLoadHistoryWhenItemContentsFails() {
        // 1. Setup mock to fail with one of the items
        orderManager.order = history2.map({$0.fsId.uuidString}) as NSArray
        orderManager.shouldReadSucceed = true
        let contents = history2.map({historyFM.getUrl(forItemWithId: $0.fsId)})
        fileManager.directoryContents[Constants.urls.history] = contents
        // Make the 2nd item fail
        makeStoredItemReadable(history2[0])
        fileManager.directoryContents[historyFM.getUrl(forItemWithId: history2[1].fsId)] = nil
        makeStoredItemReadable(history2[2])
        // Expect 2 errors:
        // - Failed to load contents
        // - Didn't find item in order
        let err = expectation(description: "Error logged")
        err.expectedFulfillmentCount = 2
        let alert = expectation(description: "Error shown")
        alert.expectedFulfillmentCount = 2
        errorLogger.expectation = err
        alerter.expectation = alert
        // Expect 2 items, and not the 1st item
        let itemsExp = expectation(description: "History items")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. Should contain 2 items and errors should have happened
        history.subscribe { items, _ in
            if items.count == 2 && !items.contains(where: {$0.fsId == self.history2[1].fsId}) {
                itemsExp.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
    
    func testLoadHistoryWhenItemNotInOrder() {
        // 1. Setup mock to fail with one of the items
        orderManager.order = history2.map({$0.fsId.uuidString}) as NSArray
        orderManager.shouldReadSucceed = true
        let storedHistory = history2.with(element: HistoryItem(fsId: UUID(), types: [.string], cache: cache), insertedAt: 3)
        let contents = storedHistory.map({historyFM.getUrl(forItemWithId: $0.fsId)})
        fileManager.directoryContents[Constants.urls.history] = contents
        // Make no items fail
        makeStoredItemReadable(storedHistory[0])
        makeStoredItemReadable(storedHistory[1])
        makeStoredItemReadable(storedHistory[2])
        makeStoredItemReadable(storedHistory[3])
        // Expect 1 errors:
        // - Didn't find item in order
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        // Expect 4 items, and last item moved to the first
        let itemsExp = expectation(description: "History items")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. Should contain 2 items and errors should have happened
        history.subscribe { items, _ in
            if items.count == 4 && items[0].fsId == storedHistory[3].fsId {
                itemsExp.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
    
    func testLoadHistoryWhenItemInOrderMissing() {
        // 1. Setup mock to fail with one of the items
        orderManager.order = history2.map({$0.fsId.uuidString}) as NSArray
        orderManager.shouldReadSucceed = true
        let storedHistory = history2.without(elementAt: 1)
        let contents = storedHistory.map({historyFM.getUrl(forItemWithId: $0.fsId)})
        fileManager.directoryContents[Constants.urls.history] = contents
        // Make the no stored items fail
        makeStoredItemReadable(history2[0])
        makeStoredItemReadable(history2[2])
        // Expect 1 errors:
        // - Didn't find order item in storage
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        // Expect 2 items, and the middle item missing
        let itemsExp = expectation(description: "History items")
        
        // 2. Get the history
        let history = History(historyFM: historyFM, cache: cache, items: historyFM.loadHistory(cache: cache))
        
        // 3. Should contain 2 items and errors should have happened
        history.subscribe { items, _ in
            if items.count == 2 && !items.contains(where: {$0.fsId == self.history2[1].fsId}) {
                itemsExp.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
    
    // MARK: - insertItem()
    func testInsertItemWhenUnsavedDataNil() {
        // 1. Setup item
        let item = HistoryItem(fsId: UUID(), types: [.string], cache: cache)
        // Expect 1 error:
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        
        // 2. Insert item
        historyFM.insertItem(item, historyOrder: [item])
        
        // 3. Wait for the errors
        waitForExpectations(timeout: 1)
    }
    
    func testInsertItemWhenFailsToCreateNewDirectory() {
        // 1. Setup to fail inserting item into history2 at 0
        fileManager.createDirectory[historyFM.getUrl(forItemWithId: history2[0].fsId)] = false
        // Expect 1 error:
        // - Didn't find order item in storage
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        
        // 2. Call
        historyFM.insertItem(history2[0], historyOrder: history2)
        
        // 3. Wait for errors
        waitForExpectations(timeout: 1)
    }
    
    func testInsertItemWhenFailsToWriteData() {
        let history = [
            HistoryItem(unsavedData: [.string: "Test".data(using: .utf8)!], cache: cache)
        ]
        // 1. Setup to succeed creating a directory but fail data write
        fileManager.createDirectory[historyFM.getUrl(forItemWithId: history[0].fsId)] = true
        dataFileMangaer.writeDataSucceeds[historyFM.getUrl(forItemWithId: history[0].fsId, andPasteboardType: .string)] = false
        // Expect 1 error:
        // - Fail to write data
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        
        // 2. Call
        historyFM.insertItem(history[0], historyOrder: history)
        
        // 3. Wait for errors
        waitForExpectations(timeout: 1)
    }
    
    func testInsertItemSuccessful() {
        let history = [
            HistoryItem(unsavedData: [.string: "Test".data(using: .utf8)!], cache: cache)
        ]
        // 1. Setup to succeed creating a directory but fail data write
        fileManager.createDirectory[historyFM.getUrl(forItemWithId: history[0].fsId)] = true
        dataFileMangaer.writeDataSucceeds[historyFM.getUrl(forItemWithId: history[0].fsId, andPasteboardType: .string)] = true
        // Expect succes:
        let success = expectation(description: "Success")
        
        // 2. Call
        historyFM.insertItem(history[0], historyOrder: history) { res in
            if res {
                success.fulfill()
            }
        }
        
        // 3. Wait for success, no more unsaved data and should be caching
        waitForExpectations(timeout: 1, handler: { _ in
            XCTAssertNil(history[0].unsavedData)
            XCTAssertTrue(self.cache.isItemRegistered(history[0].fsId))
        })
    }
    
    
    // MARK: - deleteItem()
    func testDeleteItemWhenDeleteFolderFails() {
        // 1. Setup the mock to fail
        let deleted = HistoryItem(fsId: UUID(), types: [], cache: cache)
        fileManager.removeItem[historyFM.getUrl(forItemWithId: deleted.fsId)] = false
        // Expect 1 error
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        let failure = expectation(description: "Fails")
        
        // 2. Call
        historyFM.deleteItem(newHistory: [], deleted: deleted) { res in
            if !res {
                failure.fulfill()
            }
        }
        
        // 3. Wait for errors
        waitForExpectations(timeout: 1)
    }
    
    func testDeleteItemSuccess() {
        // 1. Setup the mock to succeed
        let deleted = HistoryItem(fsId: UUID(), types: [], cache: cache)
        fileManager.removeItem[historyFM.getUrl(forItemWithId: deleted.fsId)] = true
        // Expect success
        let success = expectation(description: "Succeeds")
        
        // 2. Call
        historyFM.deleteItem(newHistory: [], deleted: deleted) { res in
            if res {
                success.fulfill()
            }
        }
        
        // 3. Wait for errors — disk delete succeeds; cache unregister is History's job on main (T13).
        waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(self.fileManager.removeItem[self.historyFM.getUrl(forItemWithId: deleted.fsId)] == true
                || !self.fileManager.fileExists(atPath: self.historyFM.getUrl(forItemWithId: deleted.fsId).path))
            deleted.stopCaching()
            XCTAssertFalse(self.cache.isItemRegistered(deleted.fsId))
        }
    }
    
    
    // MARK: - moveItem()
    func testWhenMoveItemNewOrderSaved() {
        // 1. Set original order to history2
        let originalOrder = history2.map({$0.fsId.uuidString})
        orderManager.order = originalOrder as NSArray
        orderManager.shouldReadSucceed = true
        orderManager.shouldWriteSucceed = true
        XCTAssertEqual(historyFM.loadHistoryOrder()!.map({$0.uuidString}), originalOrder)
        let orderSaved = expectation(description: "Order saved")
        
        // 2. Change the history2 order
        let newHistory = [history2[1], history2[2], history2[0]]
        let newOrder = newHistory.map({$0.fsId.uuidString})
        historyFM.moveItem(newHistory: newHistory, from: 0, to: 2) { res in
            if res {
                orderSaved.fulfill()
            }
        }
        
        // 3. Assert that the new history order has been saved.
        waitForExpectations(timeout: 2, handler: { _ in
            XCTAssertEqual(self.historyFM.loadHistoryOrder()!.map({$0.uuidString}), newOrder)
        })
    }
    
    
    // MARK: - clearHistory()
    func testClearHistoryWhenRemoveOldHistoryFails() {
        // 1. Setup mock to fail
        fileManager.removeItem[Constants.urls.history] = false
        // Expect error
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        let failure = expectation(description: "Fails")
        
        // 2. Call
        historyFM.clearHistory() { res in
            if !res {
                failure.fulfill()
            }
        }
        
        // 3. Wait for error
        waitForExpectations(timeout: 1)
    }
    
    func testClearHistoryWhenCreateNewHistoryFails() {
        // 1. Setup mock to fail
        fileManager.removeItem[Constants.urls.history] = true
        fileManager.createDirectory[Constants.urls.history] = false
        // Expect error
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        errorLogger.expectation = err
        alerter.expectation = alert
        let failure = expectation(description: "Fails")
        
        // 2. Call
        historyFM.clearHistory() { res in
            if !res {
                failure.fulfill()
            }
        }
        
        // 3. Wait for error
        waitForExpectations(timeout: 1)
    }
    
    func testClearHistorySuccessful() {
        // 1. Setup mock to succeed
        fileManager.removeItem[Constants.urls.history] = true
        fileManager.createDirectory[Constants.urls.history] = true
        // Expect success
        let success = expectation(description: "Succeeds")
        
        // 2. Call
        historyFM.clearHistory() { res in
            if res {
                success.fulfill()
            }
        }
        
        // 3. Wait for error
        waitForExpectations(timeout: 1)
    }
    
        
    // MARK: - Coalesced order writes (P7)

    func testOrderWritesAreCoalescedIntoOneDiskHit() {
        historyFM.orderCoalesceInterval = 0.4
        let flushes = expectation(description: "all handlers fire")
        flushes.expectedFulfillmentCount = 3

        historyFM.scheduleHistoryOrderWrite(history: history1) { _ in flushes.fulfill() }
        historyFM.scheduleHistoryOrderWrite(history: history2) { _ in flushes.fulfill() }
        historyFM.scheduleHistoryOrderWrite(history: history1) { _ in flushes.fulfill() }

        wait(for: [flushes], timeout: 3)
        XCTAssertEqual(orderManager.writeCount, 1, "burst must collapse to a single order write")
        XCTAssertEqual(orderManager.order as? [String], history1.map { $0.fsId.uuidString }, "last snapshot wins")
    }

    func testImmediateScheduleFlushesWithoutWaitingForCoalesceWindow() {
        historyFM.orderCoalesceInterval = 60
        let done = expectation(description: "immediate flush")

        historyFM.scheduleHistoryOrderWrite(history: history1, immediate: true) { _ in done.fulfill() }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(orderManager.writeCount, 1)
    }

    func testSyncFlushDrainsPendingOrderWithinTimeout() {
        // `flushHistoryOrderSync` blocks the caller until the file-manager queue drains,
        // so it must never be exercised with a main-queue manager (that would deadlock).
        let backgroundManager = HistoryFileManager(
            fileManager: fileManager,
            orderManager: orderManager,
            dataFileManager: dataFileMangaer,
            dispatchQueue: DispatchQueue(label: "SyncFlushTestQueue"),
            errorLogger: errorLogger,
            warningLogger: warningLogger,
            alerter: alerter
        )
        backgroundManager.orderCoalesceInterval = 30
        let order = history2.map { $0.fsId.uuidString }
        backgroundManager.scheduleHistoryOrderWrite(history: history2, immediate: false, completionHandler: nil)

        backgroundManager.flushHistoryOrderSync(timeout: 2)

        XCTAssertEqual(orderManager.order as? [String], order)
    }

    func testClearHistoryDiscardsPendingSnapshot() {
        fileManager.removeItem[Constants.urls.history] = true
        fileManager.createDirectory[Constants.urls.history] = true
        let done = expectation(description: "cleared")

        // A pending non-empty order queued just before the clear must not resurrect itself.
        historyFM.scheduleHistoryOrderWrite(history: history2, immediate: false, completionHandler: nil)
        historyFM.clearHistory { res in
            XCTAssertTrue(res)
            done.fulfill()
        }

        wait(for: [done], timeout: 2)
        XCTAssertEqual(orderManager.order as? [String], [])
    }

    // MARK: - deleteItems() continues past failures (D3)

    func testDeleteItemsKeepsDeletingAndStillRewritesOrderAfterFailure() {
        let kept = history2[0]
        let failing = history2[1]
        let removable = history2[2]
        fileManager.removeItem[historyFM.getUrl(forItemWithId: failing.fsId)] = false
        fileManager.removeItem[historyFM.getUrl(forItemWithId: removable.fsId)] = true
        let err = expectation(description: "Error logged")
        let alert = expectation(description: "Error shown")
        err.assertForOverFulfill = false
        alert.assertForOverFulfill = false
        errorLogger.expectation = err
        alerter.expectation = alert
        let finished = expectation(description: "handler called")

        historyFM.deleteItems([failing, removable], historyOrder: [kept]) { res in
            XCTAssertFalse(res, "overall result reports the failed removal")
            finished.fulfill()
        }

        wait(for: [err, alert, finished], timeout: 2)
        XCTAssertEqual(orderManager.order as? [String], [kept.fsId.uuidString],
                       "order must be rewritten even when one directory could not be removed")
    }

    // MARK: - loadHistoryAsync() (P6)

    func testLoadHistoryAsyncCompletesOnMainQueueWithLoadedHistory() {
        orderManager.order = [] as NSArray
        orderManager.shouldReadSucceed = true
        fileManager.directoryContents[Constants.urls.history] = []
        let loaded = expectation(description: "async load")

        historyFM.loadHistoryAsync(cache: cache) { items in
            let history = History(historyFM: self.historyFM, cache: self.cache, items: items)
            dispatchPrecondition(condition: .onQueue(.main))
            XCTAssertEqual(history.items.count, 0)
            loaded.fulfill()
        }

        wait(for: [loaded], timeout: 2)
    }

    // MARK: - getUrl() - Item
    func testGetUrlForItemReturnsCorrectUrl() {
        // 1. Create an id
        let id = UUID()
        
        // 2. Get the url for the item id
        let url = historyFM.getUrl(forItemWithId: id)
        
        // 3. Should be a directory named after the id
        XCTAssertEqual(url.lastPathComponent, id.uuidString)
        XCTAssertTrue(url.hasDirectoryPath)
        // Should be in the history folder
        XCTAssertEqual(url.deletingLastPathComponent(), Constants.urls.history)
    }
    
    
    // MARK: - getUrl() - Data
    func testGetUrlForItemDataReturnsCorrectUrl() {
        // 1. Create an id and pasteboard type
        let id = UUID()
        let type = NSPasteboard.PasteboardType.color
        
        // 2. Get the url for the item id
        let url = historyFM.getUrl(forItemWithId: id, andPasteboardType: type)
        let itemUrl = historyFM.getUrl(forItemWithId: id)
        
        // 3. Should be a file named after the type rawValue.
        XCTAssertEqual(url.lastPathComponent, type.rawValue)
        XCTAssertTrue(!url.hasDirectoryPath)
        // Should be in the item folder
        XCTAssertEqual(url.deletingLastPathComponent(), itemUrl)
    }
}

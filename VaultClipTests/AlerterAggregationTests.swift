//
// AlerterAggregationTests — coalesced error alerts (T18).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

private final class RecordingPresenter: AlertPresenting {
    private(set) var presentations: [(title: String, message: String)] = []
    func present(title: String, message: String, openLogs: Bool) {
        presentations.append((title, message))
    }
}

final class AlerterAggregationTests: XCTestCase {

    func testFiveErrorsProduceOnePresentationWithCount() {
        let presenter = RecordingPresenter()
        let alerter = Alerter(presenter: presenter)
        let shown = expectation(description: "aggregated alert")

        for i in 1...5 {
            alerter.enqueue("error \(i)")
        }

        // Flush runs on main after coalesce delay 0 when never presented.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(presenter.presentations.count, 1)
            XCTAssertTrue(presenter.presentations[0].message.contains("5"))
            XCTAssertTrue(presenter.presentations[0].message.contains("error 5"))
            shown.fulfill()
        }
        wait(for: [shown], timeout: 2)
    }
}

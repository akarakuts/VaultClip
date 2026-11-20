//
// PasswordAccessGateTests — grace period and lock/sleep reset (T29).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

private final class MockAuthenticator: Authenticating {
    var results: [Bool] = []
    private(set) var callCount = 0

    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        callCount += 1
        let ok = results.isEmpty ? true : results.removeFirst()
        completion(ok)
    }
}

final class PasswordAccessGateTests: XCTestCase {
    private var previousRequires: Bool!
    private var previousGrace: Int!
    private var gate: PasswordAccessGate!
    private var mock: MockAuthenticator!

    override func setUp() {
        super.setUp()
        previousRequires = Settings.main.requiresPasswordAuthentication
        previousGrace = Settings.main.passwordAuthGraceMinutes
        SettingsPersistence.apply {
            $0.requiresPasswordAuthentication = true
            $0.passwordAuthGraceMinutes = 5
        }
        mock = MockAuthenticator()
        gate = PasswordAccessGate()
        gate.authenticator = mock
        var clock = Date(timeIntervalSince1970: 1_000)
        gate.now = { clock }
        // Expose clock bump via associated object substitute: recreate with mutable box
        let box = DateBox(date: clock)
        gate.now = { box.date }
        self.dateBox = box
        PanelFocusGuard.resetForTests()
    }

    private var dateBox: DateBox!

    override func tearDown() {
        SettingsPersistence.apply {
            $0.requiresPasswordAuthentication = previousRequires
            $0.passwordAuthGraceMinutes = previousGrace
        }
        PanelFocusGuard.resetForTests()
        super.tearDown()
    }

    func testGracePeriodSkipsSecondAuth() {
        mock.results = [true]
        let first = expectation(description: "first")
        gate.authorize { ok in
            XCTAssertTrue(ok)
            first.fulfill()
        }
        wait(for: [first], timeout: 1)
        XCTAssertEqual(mock.callCount, 1)

        let second = expectation(description: "second")
        gate.authorize { ok in
            XCTAssertTrue(ok)
            second.fulfill()
        }
        wait(for: [second], timeout: 1)
        XCTAssertEqual(mock.callCount, 1, "grace should skip re-auth")
    }

    func testResetGraceForcesReauth() {
        mock.results = [true, true]
        let first = expectation(description: "first")
        gate.authorize { _ in first.fulfill() }
        wait(for: [first], timeout: 1)
        gate.resetGrace()
        let second = expectation(description: "second")
        gate.authorize { _ in second.fulfill() }
        wait(for: [second], timeout: 1)
        XCTAssertEqual(mock.callCount, 2)
    }

    func testDisabledSettingSkipsAuth() {
        SettingsPersistence.apply { $0.requiresPasswordAuthentication = false }
        let done = expectation(description: "done")
        gate.authorize { ok in
            XCTAssertTrue(ok)
            done.fulfill()
        }
        wait(for: [done], timeout: 1)
        XCTAssertEqual(mock.callCount, 0)
    }
}

private final class DateBox {
    var date: Date
    init(date: Date) { self.date = date }
}

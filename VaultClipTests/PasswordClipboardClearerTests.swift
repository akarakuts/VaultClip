//
// PasswordClipboardClearerTests — clear only when changeCount still matches (T30).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

private final class ImmediateScheduler: ClipboardClearScheduling {
    var pending: (() -> Void)?
    func schedule(after seconds: TimeInterval, execute: @escaping () -> Void) {
        pending = execute
    }
    func cancel() { pending = nil }
    func fire() { pending?(); pending = nil }
}

final class PasswordClipboardClearerTests: XCTestCase {
    private var previousSeconds: Int!

    override func setUp() {
        super.setUp()
        previousSeconds = Settings.main.passwordClipboardClearSeconds
        SettingsPersistence.apply { $0.passwordClipboardClearSeconds = 90 }
    }

    override func tearDown() {
        SettingsPersistence.apply { $0.passwordClipboardClearSeconds = previousSeconds }
        super.tearDown()
    }

    func testClearsWhenChangeCountUnchanged() {
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.clear.ok"))
        pb.clearContents()
        pb.setString("secret", forType: .string)
        let count = pb.changeCount
        let clearer = PasswordClipboardClearer()
        let scheduler = ImmediateScheduler()
        clearer.scheduler = scheduler
        clearer.scheduleClear(afterWritingChangeCount: count, pasteboard: pb)
        scheduler.fire()
        XCTAssertNil(pb.string(forType: .string))
    }

    func testSkipsWhenUserCopiedSomethingElse() {
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.clear.skip"))
        pb.clearContents()
        pb.setString("secret", forType: .string)
        let count = pb.changeCount
        let clearer = PasswordClipboardClearer()
        let scheduler = ImmediateScheduler()
        clearer.scheduler = scheduler
        clearer.scheduleClear(afterWritingChangeCount: count, pasteboard: pb)
        pb.clearContents()
        pb.setString("other", forType: .string)
        XCTAssertNotEqual(pb.changeCount, count)
        scheduler.fire()
        XCTAssertEqual(pb.string(forType: .string), "other")
    }
}

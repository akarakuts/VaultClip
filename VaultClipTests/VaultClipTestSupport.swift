//
// VaultClipTestSupport — restore AppEnvironment after tests that replace shared singletons.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

enum VaultClipTestSupport {

    /// Re-installs pointers cleared by tests so the test host keeps working.
    static func reinstallSharedPointers(from environment: AppEnvironment?) {
        guard let environment else {
            State.installShared(nil)
            Controller.installShared(nil)
            Settings.bootstrapOverride = nil
            return
        }
        AppEnvironment.shared = environment
        State.installShared(environment.state)
        Settings.installShared(environment.settings)
        Controller.installShared(environment.controller)
    }
}

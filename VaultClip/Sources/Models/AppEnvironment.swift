//
// AppEnvironment — composition root; single entry for app-wide dependencies.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// Holds `Settings`, `State`, and `Controller` for the running process.
final class AppEnvironment {

    static var shared: AppEnvironment!

    var settings: Settings
    let state: State
    private(set) var controller: Controller?

    private init(settings: Settings) {
        self.settings = settings
        self.state = State(settings: settings)
    }

  // MARK: - Accessors

    var routing: AppRouting {
        guard let controller else {
            preconditionFailure("Controller not attached — call attachController() after bootstrap")
        }
        return controller
    }

  // MARK: - Bootstrap

    @discardableResult
    static func bootstrap(settings: Settings? = nil) -> AppEnvironment {
        let resolved = settings ?? Settings.bootstrapOverride ?? Settings.loadPersisted()
        let environment = AppEnvironment(settings: resolved)
        shared = environment
        State.installShared(environment.state)
        Settings.installShared(resolved)
        return environment
    }

    func attachController(_ controller: Controller) {
        self.controller = controller
        Controller.installShared(controller)
    }

  // MARK: - Settings persistence

    func updateSettings(_ mutate: (inout Settings) -> Void) {
        mutate(&settings)
        settings.persist()
        Settings.installShared(settings)
    }
}

//
// SettingsPersistence — single write path for Settings (via AppEnvironment or test override).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum SettingsPersistence {

    static func current() -> Settings {
        if let env = AppEnvironment.shared { return env.settings }
        if let override = Settings.bootstrapOverride { return override }
        return Settings.loadPersisted()
    }

    static func apply(_ mutate: (inout Settings) -> Void) {
        if let env = AppEnvironment.shared {
            env.updateSettings(mutate)
            return
        }
        var settings = Settings.bootstrapOverride ?? Settings.loadPersisted()
        mutate(&settings)
        settings.persist()
        Settings.installShared(settings)
    }
}

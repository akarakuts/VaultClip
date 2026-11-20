//
// SettingsPersistence — single write path for Settings (via AppEnvironment or test override).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension Notification.Name {
    /// Posted after every SettingsPersistence.apply so UI outside the panel (status item) can follow.
    static let vaultClipSettingsDidChange = Notification.Name("VaultClipSettingsDidChange")
}

enum SettingsPersistence {

    static func current() -> Settings {
        if let env = AppEnvironment.shared { return env.settings }
        if let override = Settings.shared { return override }
        return Settings.loadPersisted()
    }

    static func apply(_ mutate: (inout Settings) -> Void) {
        defer { NotificationCenter.default.post(name: .vaultClipSettingsDidChange, object: nil) }
        if let env = AppEnvironment.shared {
            env.updateSettings(mutate)
            return
        }
        var settings = Settings.shared ?? Settings.loadPersisted()
        mutate(&settings)
        settings.persist()
        Settings.installShared(settings)
    }
}

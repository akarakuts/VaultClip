//
// SettingsStore — @Observable adapter over SettingsPersistence (U29).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {
    private(set) var settings: Settings

    init(settings: Settings = Settings.default) {
        self.settings = settings
    }

    func apply(_ mutate: (inout Settings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        SettingsPersistence.apply { $0 = copy }
    }

    func refreshFromPersistence() {
        settings = SettingsPersistence.current()
    }

    // Convenience typed setters used by SwiftUI forms / tests.
    var statusItemClickMode: StatusItemClickMode {
        get { settings.statusItemClickMode }
        set { apply { $0.statusItemClickMode = newValue } }
    }

    var showsRecentInMenu: Bool {
        get { settings.showsRecentInMenu }
        set { apply { $0.showsRecentInMenu = newValue } }
    }

    var recentMenuCount: Int {
        get { settings.recentMenuCount }
        set { apply { $0.recentMenuCount = newValue } }
    }

    var previewVisible: Bool {
        get { settings.previewVisible }
        set { apply { $0.previewVisible = newValue } }
    }

    var panelTextSize: TextSizePreference {
        get { settings.panelTextSize }
        set { apply { $0.panelTextSize = newValue } }
    }

    var groupHistoryByDate: Bool {
        get { settings.groupHistoryByDate }
        set { apply { $0.groupHistoryByDate = newValue } }
    }
}

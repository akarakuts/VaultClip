//
// SettingsStore — @Observable adapter over SettingsPersistence (U29).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import HotKey
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

    var previewPlacement: PreviewPlacement {
        get { settings.previewPlacement }
        set { apply { $0.previewPlacement = newValue } }
    }

    var panelTextSize: TextSizePreference {
        get { settings.panelTextSize }
        set { apply { $0.panelTextSize = newValue } }
    }

    var groupHistoryByDate: Bool {
        get { settings.groupHistoryByDate }
        set { apply { $0.groupHistoryByDate = newValue } }
    }

    var showsFilterBarPreference: Bool {
        get { settings.showsFilterBarPreference }
        set { apply { $0.showsFilterBarPreference = newValue } }
    }

    var showKeyHints: Bool {
        get { settings.showKeyHints }
        set { apply { $0.showKeyHints = newValue } }
    }

    var resetFiltersOnClose: Bool {
        get { settings.resetFiltersOnClose }
        set { apply { $0.resetFiltersOnClose = newValue } }
    }

    var reopenLastTab: Bool {
        get { settings.reopenLastTab }
        set { apply { $0.reopenLastTab = newValue } }
    }

    var selectSecondItem: Bool {
        get { settings.selectSecondItem }
        set { apply { $0.selectSecondItem = newValue } }
    }

    var pastesRichText: Bool {
        get { settings.pastesRichText }
        set { apply { $0.pastesRichText = newValue } }
    }

    var showsRichText: Bool {
        get { settings.showsRichText }
        set { apply { $0.showsRichText = newValue } }
    }

    var multiPasteSeparator: MultiPasteSeparator {
        get { MultiPasteSeparator(rawValue: settings.multiPasteSeparator) ?? .newline }
        set { apply { $0.multiPasteSeparator = newValue.rawValue } }
    }

    var usesMonospacedContentFont: Bool {
        get { settings.usesMonospacedContentFont }
        set { apply { $0.usesMonospacedContentFont = newValue } }
    }

    var panelPosition: PanelPosition {
        get { settings.panelPosition }
        set { apply { $0.panelPosition = newValue } }
    }

    var maxHistory: Int {
        get { settings.maxHistory }
        set { apply { $0.maxHistory = newValue } }
    }

    var maxItemSizeMB: Int {
        get { settings.maxItemSizeMB }
        set { apply { $0.maxItemSizeMB = newValue } }
    }

    var retentionDays: Int {
        get { settings.retentionDays }
        set { apply { $0.retentionDays = newValue } }
    }

    var requiresPasswordAuthentication: Bool {
        get { settings.requiresPasswordAuthentication }
        set { apply { $0.requiresPasswordAuthentication = newValue } }
    }

    var passwordAuthGraceMinutes: Int {
        get { settings.passwordAuthGraceMinutes }
        set { apply { $0.passwordAuthGraceMinutes = newValue } }
    }

    var passwordClipboardClearSeconds: Int {
        get { settings.passwordClipboardClearSeconds }
        set { apply { $0.passwordClipboardClearSeconds = newValue } }
    }

    var isCapturePaused: Bool {
        get { settings.isCapturePaused }
        set { apply { $0.isCapturePaused = newValue } }
    }

    var hidesPanelFromScreenCapture: Bool {
        get { settings.hidesPanelFromScreenCapture }
        set { apply { $0.hidesPanelFromScreenCapture = newValue } }
    }

    var excludedBundleIds: [String] {
        get { settings.excludedBundleIds }
        set { apply { $0.excludedBundleIds = newValue } }
    }

    var toggleHotKey: KeyCombo {
        get { settings.toggleHotKey }
        set { apply { $0.toggleHotKey = newValue } }
    }

    var panelEdgeWidth: Double {
        get { settings.panelEdgeWidth }
        set { apply { $0.panelEdgeWidth = newValue } }
    }

    var panelEdgeHeight: Double {
        get { settings.panelEdgeHeight }
        set { apply { $0.panelEdgeHeight = newValue } }
    }
}

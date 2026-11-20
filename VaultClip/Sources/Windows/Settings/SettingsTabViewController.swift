//
// SettingsTabViewController — toolbar tabs hosting SwiftUI Form panes (U29/U30).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import SwiftUI

class SettingsTabViewController: NSTabViewController {
    private let store = SettingsStore(settings: SettingsPersistence.current())
    private var injectedState: State?
    private static let lastTabKey = "settings.lastTabIndex"

    func configure(state: State) {
        injectedState = state
        store.refreshFromPersistence()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabStyle = .toolbar
        transitionOptions = []

        addHosting(SettingsGeneralTab(store: store), title: L10n.settingsGeneral, symbol: "gearshape")
        addHosting(SettingsPanelTab(store: store), title: SettingsUICopy.t("Panel", "Панель"), symbol: "macwindow")
        addHosting(SettingsPasteTab(store: store), title: SettingsUICopy.t("Paste", "Вставка"), symbol: "doc.on.clipboard")
        addHosting(SettingsHistoryTab(store: store), title: SettingsUICopy.t("History", "История"), symbol: "clock.arrow.circlepath")
        addHosting(SettingsPrivacyTab(store: store), title: L10n.settingsPrivacy, symbol: "hand.raised")
        addHosting(SettingsShortcutsTab(store: store), title: L10n.settingsHotKey, symbol: "keyboard")

        let saved = UserDefaults.standard.integer(forKey: Self.lastTabKey)
        if saved >= 0, saved < tabViewItems.count {
            selectedTabViewItemIndex = saved
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        store.refreshFromPersistence()
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if let window = tabView.window, let tabViewItem {
            window.title = tabViewItem.label
        }
        UserDefaults.standard.set(selectedTabViewItemIndex, forKey: Self.lastTabKey)
        // Animate height to fit selected pane content.
        if let window = view.window {
            let height: CGFloat
            switch selectedTabViewItemIndex {
            case 0: height = 360
            case 1: height = 560
            case 2: height = 360
            case 3: height = 320
            case 4: height = 480
            default: height = 520
            }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                window.animator().setContentSize(NSSize(width: 600, height: height))
            }
        }
    }

    private func addHosting<Content: View>(_ root: Content, title: String, symbol: String) {
        let host = NSHostingController(rootView: root)
        let item = NSTabViewItem(viewController: host)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        addTabViewItem(item)
    }
}

/// Shared with SettingsSwiftUITabs for bilingual labels outside L10n catalog.
enum SettingsUICopy {
    static var ru: Bool { Locale.current.language.languageCode?.identifier == "ru" }
    static func t(_ en: String, _ ru: String) -> String { Self.ru ? ru : en }
}

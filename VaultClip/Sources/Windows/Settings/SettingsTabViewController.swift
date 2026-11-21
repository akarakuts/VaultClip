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
    private var isBuildingTabs = false

    func configure(state: State) {
        injectedState = state
        store.refreshFromPersistence()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabStyle = .toolbar
        transitionOptions = []
        // Adding the first item fires didSelect(0); read the saved tab first and don't persist while building.
        let saved = UserDefaults.standard.integer(forKey: Self.lastTabKey)
        isBuildingTabs = true

        addHosting(SettingsGeneralTab(store: store), title: L10n.settingsGeneral, symbol: "gearshape")
        addHosting(SettingsPanelTab(store: store), title: L10n.settingsTabPanel, symbol: "macwindow")
        addHosting(SettingsPasteTab(store: store), title: L10n.settingsTabPaste, symbol: "doc.on.clipboard")
        addHosting(SettingsHistoryTab(store: store), title: L10n.settingsTabHistory, symbol: "clock.arrow.circlepath")
        addHosting(SettingsPrivacyTab(store: store), title: L10n.settingsPrivacy, symbol: "hand.raised")
        addHosting(SettingsShortcutsTab(store: store), title: L10n.settingsHotKey, symbol: "keyboard")

        if saved >= 0, saved < tabViewItems.count {
            selectedTabViewItemIndex = saved
        }
        isBuildingTabs = false
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        store.refreshFromPersistence()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        fitWindow(to: tabView.selectedTabViewItem, animated: false)
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        guard !isBuildingTabs else { return }
        UserDefaults.standard.set(selectedTabViewItemIndex, forKey: Self.lastTabKey)
        fitWindow(to: tabViewItem, animated: true)
    }

    /// Title follows the tab; height follows the SwiftUI form's fitting size (600pt wide).
    private func fitWindow(to item: NSTabViewItem?, animated: Bool) {
        guard let window = view.window, let item else { return }
        window.title = item.label
        guard let content = item.viewController?.view else { return }
        let toolbarHeight = window.frame.height - window.contentLayoutRect.height
        let fitting = content.fittingSize.height
        let height = min(max(fitting, 220), 720)
        var frame = window.frame
        let newHeight = height + toolbarHeight
        frame.origin.y += frame.height - newHeight
        frame.size = NSSize(width: 600, height: newHeight)
        window.setFrame(frame, display: true, animate: animated)
    }

    private func addHosting<Content: View>(_ root: Content, title: String, symbol: String) {
        let host = NSHostingController(rootView: root)
        let item = NSTabViewItem(viewController: host)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        addTabViewItem(item)
    }
}


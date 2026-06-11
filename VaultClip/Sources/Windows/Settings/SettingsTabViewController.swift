//
//  SettingsTabViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class SettingsTabViewController: NSTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabViewItems[0].label = L10n.settingsGeneral
        tabViewItems[1].label = L10n.settingsHotKey
        tabViewItems[0].image = NSImage(imageLiteralResourceName: "gear")
        tabViewItems[1].image = NSImage(imageLiteralResourceName: "command")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        tabView.selectTabViewItem(at: 0)
        tabView(tabView, didSelect: tabView.tabViewItem(at: 0))
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if let window = tabView.window, let tabViewItem = tabViewItem {
            window.title = tabViewItem.label
        }
    }
}

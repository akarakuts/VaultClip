//
//  PasteboardMonitor.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class PasteboardMonitor {
    
    let intervalInSeconds: TimeInterval = 0.05
    
    private var timer: Timer!
    private var lastChangeCount: Int!
    
    var pasteboard: NSPasteboard!
    var delegate: PasteboardMonitorDelegate!
    
    private var frontmostApp: String? = nil
    
    init(pasteboard: NSPasteboard, changeCount: Int = -1, delegate: PasteboardMonitorDelegate) {
        self.pasteboard = pasteboard
        self.delegate = delegate
        self.lastChangeCount = changeCount
        
        // Registers if any application becomes active (or comes frontmost) and calls a method if it's the case.
        // https://stackoverflow.com/a/49402868
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeApp(sender:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        // TODO: Is it best to do a check straight away?
        self.checkIfPasteboardChanged()
        self.timer = Timer.scheduledTimer(withTimeInterval: intervalInSeconds, repeats: true) { (t) in
            self.checkIfPasteboardChanged()
        }
    }
    
    // Called by NSWorkspace when any application becomes active or comes frontmost.
    @objc private func activeApp(sender: NSNotification) {
        if let info = sender.userInfo,
            let content = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundle = content.bundleIdentifier
        {
            frontmostApp = bundle
        }
    }
    
    private func checkIfPasteboardChanged() {
        if lastChangeCount != pasteboard.changeCount  {
            lastChangeCount = self.pasteboard.changeCount
            let originBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? frontmostApp
            delegate.pasteboardDidChange(pasteboard, originBundleId: originBundleId)
        }
    }
    
    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

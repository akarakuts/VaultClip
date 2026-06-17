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
    
    private var pollTimer: DispatchSourceTimer?
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
        
        self.checkIfPasteboardChanged()
        startPolling()
    }

    private func startPolling() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + intervalInSeconds, repeating: intervalInSeconds)
        timer.setEventHandler { [weak self] in
            self?.checkIfPasteboardChanged()
        }
        timer.resume()
        pollTimer = timer
    }
    
    // Called by NSWorkspace when any application becomes active or comes frontmost.
    @objc private func activeApp(sender: NSNotification) {
        if let info = sender.userInfo,
            let content = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundle = content.bundleIdentifier
        {
            frontmostApp = bundle
        }
        checkIfPasteboardChanged()
    }
    
    private func checkIfPasteboardChanged() {
        if lastChangeCount != pasteboard.changeCount  {
            let previous = lastChangeCount
            lastChangeCount = self.pasteboard.changeCount
            let originBundleId = Self.clipboardOriginBundleId(trackedApp: frontmostApp)
            PasteboardDiagnostics.log(
                "changeCount \(previous ?? -1) -> \(pasteboard.changeCount), origin=\(originBundleId ?? "nil")"
            )
            delegate.pasteboardDidChange(pasteboard, originBundleId: originBundleId)
        }
    }

    /// When the history panel is key, frontmost is VaultClip — use the last non-VaultClip app as copy source.
    private static func clipboardOriginBundleId(trackedApp: String?) -> String? {
        let ownBundleId = Bundle.main.bundleIdentifier
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if frontmost == ownBundleId {
            return trackedApp
        }
        return frontmost ?? trackedApp
    }
    
    deinit {
        pollTimer?.cancel()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

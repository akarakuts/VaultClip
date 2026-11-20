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

    /// Fast polling while copies happen; slows down after an idle stretch to save power.
    static let fastInterval: TimeInterval = 0.05
    static let slowInterval: TimeInterval = 0.25
    private static let idleTicksBeforeSlow = 10

    private(set) var intervalInSeconds: TimeInterval = PasteboardMonitor.fastInterval
    private var noChangeTicks = 0

    /// Gate: history ignores observed change-count moves until the async load completes;
    /// the launch sync afterwards catches up with the live pasteboard.
    private var readyForChanges = false

    private var pollTimer: DispatchSourceTimer?
    private var lastChangeCount: Int

    let pasteboard: NSPasteboard
    let delegate: PasteboardMonitorDelegate

    private var frontmostApp: String? = nil

    init(pasteboard: NSPasteboard, changeCount: Int = -1, delegate: PasteboardMonitorDelegate) {
        self.pasteboard = pasteboard
        self.delegate = delegate
        self.lastChangeCount = changeCount

        // Registers if any application becomes active (or comes frontmost) and calls a method if it's the case.
        // https://stackoverflow.com/a/49402868
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeApp(sender:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)

        startPolling()
    }

    /// Called once the loaded history has synced with the pasteboard on the main thread.
    func historyReady(liveChangeCount: Int) {
        lastChangeCount = liveChangeCount
        readyForChanges = true
        // Catch up synchronously — no need to wait for the next timer tick.
        checkIfPasteboardChanged()
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

    private func rescheduleTimer() {
        // Re-arming from the timer's own queue keeps the source valid while running.
        pollTimer?.schedule(deadline: .now() + intervalInSeconds, repeating: intervalInSeconds)
    }

    // Called by NSWorkspace when any application becomes active or comes frontmost.
    @objc private func activeApp(sender: NSNotification) {
        if let info = sender.userInfo,
            let content = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundle = content.bundleIdentifier
        {
            frontmostApp = bundle
        }
        noChangeTicks = 0
        if intervalInSeconds != Self.fastInterval {
            intervalInSeconds = Self.fastInterval
            rescheduleTimer()
        }
        checkIfPasteboardChanged()
    }

    private func checkIfPasteboardChanged() {
        guard lastChangeCount != pasteboard.changeCount else {
            noChangeTicks += 1
            if intervalInSeconds == Self.fastInterval, noChangeTicks >= Self.idleTicksBeforeSlow {
                intervalInSeconds = Self.slowInterval
                rescheduleTimer()
            }
            return
        }
        noChangeTicks = 0
        if intervalInSeconds != Self.fastInterval {
            intervalInSeconds = Self.fastInterval
            rescheduleTimer()
        }
        // While gated we keep noticing changes but leave `lastChangeCount` untouched,
        // so `historyReady` can hand the whole backlog to the launch sync.
        guard readyForChanges else { return }
        let previous = lastChangeCount
        lastChangeCount = self.pasteboard.changeCount
        let originBundleId = Self.clipboardOriginBundleId(trackedApp: frontmostApp)
        PasteboardDiagnostics.log(
            "changeCount \(previous) -> \(pasteboard.changeCount), origin=\(originBundleId ?? "nil")"
        )
        delegate.pasteboardDidChange(pasteboard, originBundleId: originBundleId)
    }

    /// When the history panel is key, frontmost is VaultClip — use the last non-VaultClip app as copy source.
    private static func clipboardOriginBundleId(trackedApp: String?) -> String? {
        ClipboardSource.resolve(
            frontmost: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            tracked: trackedApp
        )
    }
    
    deinit {
        pollTimer?.cancel()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

//
//  AppActivation.swift
//  VaultClip
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

/// Central place for app-activation calls. `NSApplication.activate(ignoringOtherApps:)`
/// and `NSRunningApplication.activate(options:)` are deprecated from macOS 14; picking
/// the modern API once here keeps call sites honest (P9.4).
enum AppActivation {

    static func activateFrontmostApplication() {
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    static func activate(_ application: NSRunningApplication?) {
        guard let application else { return }
        if #available(macOS 14, *) {
            application.activate()
        } else {
            application.activate(options: [.activateIgnoringOtherApps])
        }
    }
}

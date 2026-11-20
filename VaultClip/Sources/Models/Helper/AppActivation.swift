//
// AppActivation — single place for NSApp / NSRunningApplication activate (macOS 14+ API).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

/// Central place for app-activation calls (P9.4).
enum AppActivation {

    static func activateFrontmostApplication() {
        NSApp.activate()
    }

    static func activate(_ application: NSRunningApplication?) {
        application?.activate()
    }
}

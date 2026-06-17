//
// SingleInstanceGuard — exit duplicate processes when login items relaunch the app.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

enum SingleInstanceGuard {

    private(set) static var isDuplicateTermination = false

    /// Returns `true` when this process should stop starting up (duplicate of an already running copy).
    @discardableResult
    static func terminateIfDuplicate() -> Bool {
        guard !ProcessInfo.processInfo.arguments.contains("--uitesting") else { return false }
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }

        let pid = ProcessInfo.processInfo.processIdentifier
        let duplicates = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != pid
        }
        guard let existing = duplicates.first else { return false }

        existing.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        isDuplicateTermination = true
        NSApp.terminate(nil)
        return true
    }
}

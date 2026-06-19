//
// SingleInstanceGuard — exit duplicate processes when login items relaunch the app.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import Darwin

enum SingleInstanceGuard {

    private(set) static var isDuplicateTermination = false

    private static var lockFileDescriptor: Int32 = -1

    static var lockFileURL: URL {
        Constants.urls.appSupport.appendingPathComponent("instance.lock", isDirectory: false)
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Returns `true` when this process should stop starting up (duplicate of an already running copy).
    @discardableResult
    static func terminateIfDuplicate() -> Bool {
        guard !isRunningUnitTests else { return false }
        guard !ProcessInfo.processInfo.arguments.contains("--uitesting") else { return false }

        if !acquireExclusiveLock() {
            activateExistingInstance()
            isDuplicateTermination = true
            NSApp.terminate(nil)
            return true
        }

        return false
    }

    // MARK: - Lock

    /// POSIX `flock` avoids the race where two processes both pass an NSWorkspace scan.
    private static func acquireExclusiveLock() -> Bool {
        do {
            try SecureStorageHelper.ensureSecureDirectory(at: Constants.urls.appSupport)
        } catch {
            return true
        }

        let fd = open(lockFileURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { return true }

        if flock(fd, LOCK_EX | LOCK_NB) != 0 {
            close(fd)
            return false
        }

        lockFileDescriptor = fd
        return true
    }

    private static func activateExistingInstance() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let pid = ProcessInfo.processInfo.processIdentifier
        let duplicates = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != pid
        }
        duplicates.first?.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
    }
}

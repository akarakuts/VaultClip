//
// PasswordAccessGate — LocalAuthentication gate for revealing/pasting passwords (T29).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Foundation
import LocalAuthentication

protocol Authenticating: AnyObject {
    func authenticate(reason: String, completion: @escaping (Bool) -> Void)
}

final class LocalAuthenticator: Authenticating {
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}

final class PasswordAccessGate {
    static let shared = PasswordAccessGate()

    var authenticator: Authenticating = LocalAuthenticator()
    /// Injectable clock for tests.
    var now: () -> Date = { Date() }
    private var lastSuccessAt: Date?
    private var lockObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    init() {
        lockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetGrace()
        }
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetGrace()
        }
    }

    deinit {
        if let lockObserver {
            DistributedNotificationCenter.default().removeObserver(lockObserver)
        }
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
    }

    func resetGrace() {
        lastSuccessAt = nil
    }

    /// Authorizes password reveal / copy / paste. Completion always on main.
    func authorize(completion: @escaping (Bool) -> Void) {
        let settings = Settings.main
        guard settings.requiresPasswordAuthentication else {
            completion(true)
            return
        }
        let graceMinutes = settings.passwordAuthGraceMinutes
        if graceMinutes > 0,
           let last = lastSuccessAt,
           now().timeIntervalSince(last) < TimeInterval(graceMinutes * 60) {
            completion(true)
            return
        }
        PanelFocusGuard.suspend()
        authenticator.authenticate(reason: L10n.passwordAuthReason) { [weak self] success in
            PanelFocusGuard.resume()
            if success {
                self?.lastSuccessAt = self?.now()
            }
            completion(success)
        }
    }
}

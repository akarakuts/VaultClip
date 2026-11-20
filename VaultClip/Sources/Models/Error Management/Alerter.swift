//
//  Alerter.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

/// Presents aggregated error alerts (injectable for tests).
protocol AlertPresenting: AnyObject {
    func present(title: String, message: String, openLogs: Bool)
}

/// Default presenter: one NSAlert with optional “Open logs folder” button.
final class ModalAlertPresenter: AlertPresenting {
    func present(title: String, message: String, openLogs: Bool) {
        PanelFocusGuard.withSuspended {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            if openLogs {
                alert.addButton(withTitle: L10n.alertOpenLogsFolder)
            }
            alert.addButton(withTitle: L10n.commonOK)
            let response = alert.runModal()
            if openLogs, response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(Constants.urls.appSupport)
            }
        }
    }
}

/// Coalesces error alerts: at most one modal every 30 s while the history panel is closed.
class Alerter {

    static var general = Alerter()

    static let coalesceInterval: TimeInterval = 30

    private let presenter: AlertPresenting
    private var pendingCount = 0
    private var lastMessage = ""
    private var lastPresentation: Date?
    private var flushScheduled = false

    init(presenter: AlertPresenting = ModalAlertPresenter()) {
        self.presenter = presenter
    }

    func show(_ alertable: Alertable) {
        guard !AppIdentity.isRunningUnitTests else { return }
        let message = alertable.createAlert().informativeText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = alertable.createAlert().messageText
        enqueue(message.isEmpty ? fallback : message)
    }

    /// Test / makeHistory helper: enqueue a plain message without building NSAlert.
    func enqueue(_ message: String) {
        DispatchQueue.main.async {
            self.pendingCount += 1
            self.lastMessage = message
            self.scheduleFlushIfNeeded()
        }
    }

    #if DEBUG
    var pendingCountForTests: Int { pendingCount }
    var lastMessageForTests: String { lastMessage }
    func resetForTests() {
        pendingCount = 0
        lastMessage = ""
        lastPresentation = nil
        flushScheduled = false
    }
    #endif

    private func scheduleFlushIfNeeded() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !flushScheduled else { return }
        flushScheduled = true
        let delay: TimeInterval
        if let last = lastPresentation {
            delay = max(0, Self.coalesceInterval - Date().timeIntervalSince(last))
        } else {
            delay = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.flushScheduled = false
            self?.flushIfAllowed()
        }
    }

    private func flushIfAllowed() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard pendingCount > 0 else { return }
        if AppEnvironment.shared?.state.isHistoryPanelShown.value == true {
            scheduleFlushIfNeeded()
            return
        }
        if let last = lastPresentation, Date().timeIntervalSince(last) < Self.coalesceInterval {
            scheduleFlushIfNeeded()
            return
        }
        let count = pendingCount
        let message = lastMessage
        pendingCount = 0
        lastMessage = ""
        lastPresentation = Date()
        let title = L10n.alertErrorsTitle
        let body = count == 1
            ? message
            : L10n.alertErrorsAggregated(count: count, lastMessage: message)
        presenter.present(title: title, message: body, openLogs: true)
    }
}

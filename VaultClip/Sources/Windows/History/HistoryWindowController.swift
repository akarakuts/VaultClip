//
//  HistoryWindowController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import RxSwift
import RxRelay

class HistoryWindowController: NSWindowController {

    private var shownToggle: BehaviorRelay<Bool>?
    private weak var appState: State?
    private var oldApp: NSRunningApplication?
    private var deactivationObservers: [NSObjectProtocol] = []
    let panelChrome = PanelChromeController()

    override func windowDidLoad() {
        super.windowDidLoad()

        // Relay is the source of truth — do not let AppKit auto-hide without updating state.
        window?.hidesOnDeactivate = false
        window?.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 2)
        window?.setAccessibilityIdentifier(Accessibility.identifiers.historyWindow)
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        if let window, let content = window.contentView {
            panelChrome.attach(to: window, contentRoot: content)
        }
        startWatchingDeactivation()
    }

    deinit {
        for observer in deactivationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    static func createHistoryWindowController() -> HistoryWindowController {
        return NSStoryboard.instantiateOrTerminate(identifier: "HistoryWindowController")
    }

    func subscribeTo(toggle: BehaviorRelay<Bool>, state: State) -> Disposable {
        shownToggle = toggle
        appState = state
        return toggle
            .subscribe(onNext: { [weak self] shown in
                guard let self else { return }
                if !shown {
                    self.close()
                    let reason = state.panelCloseReason
                    if PanelVisibilityPolicy.shouldRestoreFocus(reason: reason) {
                        AppActivation.activate(self.oldApp)
                    }
                    state.panelCloseReason = .userAction
                } else {
                    self.oldApp = NSWorkspace.shared.frontmostApplication
                    self.showWindow(nil)
                    self.window?.layoutIfNeeded()
                    self.window?.makeKey()
                    self.panelChrome.animateShow()
                    AppActivation.activateFrontmostApplication()
                    (self.contentViewController as? HistoryViewController)?
                        .alignHistoryListAfterWindowFrameChange()
                    DispatchQueue.main.async {
                        (self.contentViewController as? HistoryViewController)?
                            .alignHistoryListAfterWindowFrameChange()
                    }
                }
            })
    }

    func subscribeFrameTo(position: Observable<PanelPosition>, screen: Observable<NSScreen?>) -> Disposable {
        Observable.combineLatest(position, screen).subscribe(onNext: {
            (position, screen) in
            guard let screen else { return }
            self.panelChrome.applyChrome(for: position)
            let sizes = SettingsPersistence.current().panelSizes
            let frame = position.getFrame(forScreen: screen, sizes: sizes)
            // Content must never grow the panel past its computed frame (large preview images did).
            self.window?.contentMaxSize = frame.size
            self.window?.setFrame(frame, display: true)
            DispatchQueue.main.async {
                (self.contentViewController as? HistoryViewController)?
                    .alignHistoryListAfterWindowFrameChange()
            }
        })
    }

    // MARK: - Deactivation

    private func startWatchingDeactivation() {
        let center = NotificationCenter.default
        deactivationObservers.append(center.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeForAppDeactivationIfNeeded()
        })
        deactivationObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.bundleIdentifier != Bundle.main.bundleIdentifier {
                self?.closeForAppDeactivationIfNeeded()
            }
        })
    }

    private func closeForAppDeactivationIfNeeded() {
        guard !AppIdentity.isRunningUnitTests else { return }
        guard let toggle = shownToggle, let state = appState else { return }
        guard PanelVisibilityPolicy.shouldClose(
            reason: .appDeactivated,
            isShown: toggle.value,
            isSuspended: PanelFocusGuard.isSuspended
        ) else { return }
        state.panelCloseReason = .appDeactivated
        toggle.accept(false)
    }
}

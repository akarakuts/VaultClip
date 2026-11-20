//
//  State.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import RxRelay
import RxSwift

class State {
    
    // MARK: - Shared instance (legacy — prefer AppEnvironment.shared.state)

    private static weak var _shared: State?
    
    static var main: State {
        if let shared = _shared { return shared }
        if let env = AppEnvironment.shared { return env.state }
        preconditionFailure("State accessed before AppEnvironment.bootstrap()")
    }
    
    static func installShared(_ state: State?) {
        _shared = state
    }
    
    
    // MARK: - Attributes
    // RxSwift
    var isHistoryPanelShown: BehaviorRelay<Bool>

    /// Set before accepting `false` on `isHistoryPanelShown`; read by HistoryWindowController for focus restore.
    var panelCloseReason: PanelCloseReason = .userAction
    
    var panelPosition: BehaviorRelay<PanelPosition>

    var currentScreen: BehaviorRelay<NSScreen?>
    
    var previewHistoryItem: BehaviorRelay<HistoryItem?>
    
    var launchAtLogin: BehaviorRelay<Bool>
    
    var showsRichText: BehaviorRelay<Bool>
    
    var pastesRichText: BehaviorRelay<Bool>
    
    var disposeBag: DisposeBag

    /// Retained so the mouse-position poller can be stopped with the state (P9.1).
    private var mousePositionTimer: Timer?

    deinit {
        mousePositionTimer?.invalidate()
    }
    
    // History
    var historyCache: HistoryCache
    var history: History

    /// Async history load finished (sync path in UI tests sets it immediately).
    private(set) var isHistoryLoaded = false

    /// Monitors the pasteboard, here it can be controlled in the future if needed.
    var pasteboardMonitor: PasteboardMonitor

    // MARK: - Constructor
    init(settings: Settings, disposeBag: DisposeBag = DisposeBag()) {
        // Setup RxSwift attributes
        self.isHistoryPanelShown = BehaviorRelay<Bool>(value: false)
        self.panelPosition = BehaviorRelay<PanelPosition>(value: settings.panelPosition)
        self.previewHistoryItem = BehaviorRelay<HistoryItem?>(value: nil)
        self.launchAtLogin = BehaviorRelay<Bool>(
            value: AppIdentity.isRunningUnitTests ? false : LaunchAtLoginHelper.isEnabled()
        )
        self.showsRichText = BehaviorRelay<Bool>(value: settings.showsRichText)
        self.pastesRichText = BehaviorRelay<Bool>(value: settings.pastesRichText)
        self.currentScreen = BehaviorRelay<NSScreen?>(value: Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation))
        self.disposeBag = disposeBag

        // Setup history. Disk reads happen off the main thread so the menu-bar item
        // appears immediately; the panel shows "Loading…" until `isHistoryLoaded`.
        let historyCache = HistoryCache()
        self.historyCache = historyCache
        if UITesting.isRunning {
            // UI tests need deterministic content without pumping the run loop.
            let history = History.load(cache: historyCache)
            self.history = history
            self.isHistoryLoaded = true
            history.recordPasteboardChange(withCount: settings.pasteboardChangeCount)
            history.setMaxItems(settings.maxHistory)
        } else {
            let history = History(historyFM: HistoryFileManager.default, cache: historyCache, items: [])
            self.history = history
            history.recordPasteboardChange(withCount: settings.pasteboardChangeCount)
            history.setMaxItems(settings.maxHistory)
        }

        // Setup pasteboard monitor (private pasteboard for the XCTest host — never the system clipboard).
        let monitoredPasteboard = Self.pasteboardForProcess()
        self.pasteboardMonitor = PasteboardMonitor(
            pasteboard: monitoredPasteboard,
            changeCount: settings.pasteboardChangeCount,
            delegate: history
        )

        // Bind settings to state
        Self.bind(settings: settings, toState: self, disposeBag: disposeBag)

        if isHistoryLoaded {
            history.syncWithPasteboardOnLaunch(monitoredPasteboard)
            pasteboardMonitor.historyReady(liveChangeCount: monitoredPasteboard.changeCount)
        } else {
            History.loadAsync(historyFM: HistoryFileManager.default, cache: historyCache) { [weak self] loaded in
                guard let self else { return }
                self.isHistoryLoaded = true
                self.history.replaceLoaded(with: loaded.items)
                self.history.syncWithPasteboardOnLaunch(monitoredPasteboard)
                self.pasteboardMonitor.historyReady(liveChangeCount: monitoredPasteboard.changeCount)
            }
        }

        Self.monitorPastesRichText(state: self)
        Self.monitorMousePosition(state: self)
    }
    
    // MARK: - Constructor Helpers
    
    static func bind(settings: Settings, toState state: State, disposeBag: DisposeBag) {
        state.history.observableLastRecordedChangeCount
            .distinctUntilChanged()
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe(onNext: { count in
                SettingsPersistence.apply { $0.pasteboardChangeCount = count }
            })
            .disposed(by: disposeBag)
        settings.bindPanelPositionTo(state: state.panelPosition).disposed(by: disposeBag)
        settings.bindMaxHistoryTo(state: state.history.maxItems).disposed(by: disposeBag)
        settings.bindShowsRichTextTo(state: state.showsRichText.asObservable()).disposed(by: disposeBag)
        settings.bindPastesRichTextTo(state: state.pastesRichText.asObservable()).disposed(by: disposeBag)
    }
    
    static func monitorPastesRichText(state: State) {
        // Per-item migration (D5): the relay still persists the preference; the paste path
        // copies it onto each HistoryItem just before writing the pasteboard.
    }
    
    static func monitorMousePosition(state: State) {
        // Weak capture + retained handle so the timer stops with the state object.
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak state] _ in
            guard let state else { return }
            let currentScreen = getCurrentScreen(forMouseLocation: NSEvent.mouseLocation)
            if currentScreen != state.currentScreen.value {
                state.currentScreen.accept(currentScreen)
            }
        }
        timer.tolerance = 0.05
        state.mousePositionTimer = timer
    }

    /// Nil only when the system reports no screens at all (rare display teardown races).
    static func getCurrentScreen(forMouseLocation location: NSPoint) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(location) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    private static func pasteboardForProcess() -> NSPasteboard {
        if AppIdentity.isRunningUnitTests {
            return NSPasteboard(name: NSPasteboard.Name("com.karakuts.VaultClip.unit-tests"))
        }
        return .general
    }
}

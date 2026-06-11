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
import LoginServiceKit

class State {
    
    // MARK: - Singleton
    static var main = State()
    
    
    // MARK: - Attributes
    // RxSwift
    var isHistoryPanelShown: BehaviorRelay<Bool>
    
    var panelPosition: BehaviorRelay<PanelPosition>
    
    var currentScreen: BehaviorRelay<NSScreen>
    
    var previewHistoryItem: BehaviorRelay<HistoryItem?>
    
    var launchAtLogin: BehaviorRelay<Bool>
    
    var showsRichText: BehaviorRelay<Bool>
    
    var pastesRichText: BehaviorRelay<Bool>
    
    var disposeBag: DisposeBag
    
    // History
    var historyCache: HistoryCache!
    var history: History!
    
    /// Monitors the pasteboard, here it can be controlled in the future if needed.
    var pasteboardMonitor: PasteboardMonitor!
    
    
    // MARK: - Constructor
    init(settings: Settings = Settings.main, disposeBag: DisposeBag = DisposeBag()) {
        // Setup RxSwift attributes
        self.isHistoryPanelShown = BehaviorRelay<Bool>(value: false)
        self.panelPosition = BehaviorRelay<PanelPosition>(value: settings.panelPosition)
        self.previewHistoryItem = BehaviorRelay<HistoryItem?>(value: nil)
        self.launchAtLogin = BehaviorRelay<Bool>(value: LaunchAtLoginHelper.isEnabled())
        self.showsRichText = BehaviorRelay<Bool>(value: settings.showsRichText)
        self.pastesRichText = BehaviorRelay<Bool>(value: settings.pastesRichText)
        self.currentScreen = BehaviorRelay<NSScreen>(value: Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation))
        self.disposeBag = disposeBag
        
        // Setup history
        self.historyCache = HistoryCache()
        self.history = History.load(cache: historyCache)
        self.history.recordPasteboardChange(withCount: settings.pasteboardChangeCount)
        self.history.setMaxItems(settings.maxHistory)
        
        // Bind settings to state
        Self.bind(settings: settings, toState: self, disposeBag: disposeBag)
        
        // Setup pasteboard monitor
        self.pasteboardMonitor = PasteboardMonitor(pasteboard: NSPasteboard.general, changeCount: settings.pasteboardChangeCount, delegate: self.history)
        self.history.syncWithPasteboardOnLaunch(NSPasteboard.general)
        
        Self.monitorPastesRichText(state: self)
        Self.monitorMousePosition(state: self)
    }
    
    // MARK: - Constructor Helpers
    
    static func bind(settings: Settings, toState state: State, disposeBag: DisposeBag) {
        state.history!.observableLastRecordedChangeCount
            .distinctUntilChanged()
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe(onNext: { count in
                Settings.main.pasteboardChangeCount = count
            })
            .disposed(by: disposeBag)
        settings.bindPanelPositionTo(state: state.panelPosition).disposed(by: disposeBag)
        settings.bindMaxHistoryTo(state: state.history.maxItems).disposed(by: disposeBag)
        settings.bindShowsRichTextTo(state: state.showsRichText.asObservable()).disposed(by: disposeBag)
        settings.bindPastesRichTextTo(state: state.pastesRichText.asObservable()).disposed(by: disposeBag)
    }
    
    static func monitorPastesRichText(state: State) {
        state.pastesRichText.distinctUntilChanged().subscribe(onNext: {
            HistoryItem.pastesRichText = $0
        }).disposed(by: state.disposeBag)
    }
    
    static func monitorMousePosition(state: State) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (_) in
            let currentScreen = getCurrentScreen(forMouseLocation: NSEvent.mouseLocation)
            if currentScreen != state.currentScreen.value {
                state.currentScreen.accept(currentScreen)
            }
        }
    }
    
    static func getCurrentScreen(forMouseLocation location: NSPoint) -> NSScreen {
        for screen in NSScreen.screens {
            if screen.frame.contains(location) {
                return screen
            }
        }
        return NSScreen.screens.first ?? NSScreen.main!
    }
}

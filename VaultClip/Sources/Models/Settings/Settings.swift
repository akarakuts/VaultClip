//
//  Settings.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import RxSwift
import RxRelay
import HotKey

struct Settings: Codable, DefaultStorable {
    
    // MARK: - Singleton
    
    // MARK: - Shared instance (via AppEnvironment)

    static var bootstrapOverride: Settings?

    static func installShared(_ settings: Settings) {
        bootstrapOverride = settings
    }

    static func loadPersisted() -> Settings {
        read(forKey: "settings") ?? .default
    }

    static var main: Settings {
        get { SettingsPersistence.current() }
        set { SettingsPersistence.apply { $0 = newValue } }
    }

    private init(
        panelPosition: PanelPosition,
        pasteboardChangeCount: Int,
        toggleHotKey: KeyCombo,
        maxHistory: Int,
        showsRichText: Bool,
        pastesRichText: Bool
    ) {
        self.panelPosition = panelPosition
        self.pasteboardChangeCount = pasteboardChangeCount
        self.toggleHotKey = toggleHotKey
        self.maxHistory = maxHistory
        self.showsRichText = showsRichText
        self.pastesRichText = pastesRichText
    }
    
    static let `default` = Settings(
        panelPosition: .right,
        pasteboardChangeCount: -1,
        toggleHotKey: KeyCombo(key: .v, modifiers: [.command, .shift]),
        maxHistory: Constants.settings.maxHistoryItemsDefault,
        showsRichText: true,
        pastesRichText: true
    )
    
    // MARK: - Settings
    
    var panelPosition: PanelPosition
    
    var pasteboardChangeCount: Int
    
    var toggleHotKey: KeyCombo
    
    var maxHistory: Int
    
    var showsRichText: Bool
    
    var pastesRichText: Bool
    
    
    // MARK: - State Binding Methods
    
    func bindPanelPositionTo(state: BehaviorRelay<PanelPosition>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.panelPosition = x }
        }
    }

    func bindPasteboardChangeCountTo(state: Observable<Int>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.pasteboardChangeCount = x }
        }
    }

    func bindMaxHistoryTo(state: Observable<Int>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.maxHistory = x }
        }
    }

    func bindShowsRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.showsRichText = x }
        }
    }

    func bindPastesRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.pastesRichText = x }
        }
    }
}

extension Settings {

    func persist() {
        write(withKey: "settings")
    }
}

extension Settings {
    
    struct testData {
        static var a: Settings {
            var settings = Settings.default
            settings.panelPosition = .left
            return settings
        }
        
        static func from(_ str: String) -> Settings? {
            switch str {
            case "--Settings.testData=a":
                return a
            default:
                return nil
            }
        }
    }
}

extension Settings: Equatable {
    
}

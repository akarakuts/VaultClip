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

    /// The installed shared settings slot; `nil` until bootstrap or a test installs one.
    /// Prefer `AppEnvironment.shared.settings`; `Settings.main` forwards through this.
    static var shared: Settings?

    static func installShared(_ settings: Settings) {
        shared = settings
    }

    static let corruptBackupKey = "settings.corrupt-backup"

    static func loadPersisted() -> Settings {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "settings") else {
            return .default
        }
        do {
            return try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            defaults.set(data, forKey: corruptBackupKey)
            ClipWarning(localizedDescription: "Settings JSON could not be decoded; using defaults and keeping a corrupt backup.")
                .log(with: WarningLogger.general)
            return .default
        }
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
        pastesRichText: Bool,
        maxItemSizeMB: Int,
        requiresPasswordAuthentication: Bool,
        passwordAuthGraceMinutes: Int,
        passwordClipboardClearSeconds: Int
    ) {
        self.panelPosition = panelPosition
        self.pasteboardChangeCount = pasteboardChangeCount
        self.toggleHotKey = toggleHotKey
        self.maxHistory = maxHistory
        self.showsRichText = showsRichText
        self.pastesRichText = pastesRichText
        self.maxItemSizeMB = maxItemSizeMB
        self.requiresPasswordAuthentication = requiresPasswordAuthentication
        self.passwordAuthGraceMinutes = passwordAuthGraceMinutes
        self.passwordClipboardClearSeconds = passwordClipboardClearSeconds
    }
    
    static let `default` = Settings(
        panelPosition: .right,
        pasteboardChangeCount: -1,
        toggleHotKey: KeyCombo(key: .v, modifiers: [.command, .shift]),
        maxHistory: Constants.settings.maxHistoryItemsDefault,
        showsRichText: true,
        pastesRichText: true,
        maxItemSizeMB: Constants.settings.maxItemSizeMBDefault,
        requiresPasswordAuthentication: true,
        passwordAuthGraceMinutes: 5,
        passwordClipboardClearSeconds: 90
    )
    
    // MARK: - Settings
    
    var panelPosition: PanelPosition
    
    var pasteboardChangeCount: Int
    
    var toggleHotKey: KeyCombo
    
    var maxHistory: Int
    
    var showsRichText: Bool
    
    var pastesRichText: Bool

    /// Max clipboard item size in megabytes; `0` means unlimited (T26).
    var maxItemSizeMB: Int

    /// Require Touch ID / Mac password before revealing or pasting saved passwords (T29).
    var requiresPasswordAuthentication: Bool

    /// Minutes after a successful unlock when password actions skip re-auth; `0` = every time.
    var passwordAuthGraceMinutes: Int

    /// Auto-clear password clipboard after N seconds; `0` disables (T30).
    var passwordClipboardClearSeconds: Int

    enum CodingKeys: String, CodingKey {
        case panelPosition
        case pasteboardChangeCount
        case toggleHotKey
        case maxHistory
        case showsRichText
        case pastesRichText
        case maxItemSizeMB
        case requiresPasswordAuthentication
        case passwordAuthGraceMinutes
        case passwordClipboardClearSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings.default

        if let raw = try container.decodeIfPresent(Int.self, forKey: .panelPosition),
           let position = PanelPosition(rawValue: raw) {
            panelPosition = position
        } else {
            panelPosition = defaults.panelPosition
        }

        pasteboardChangeCount = try container.decodeIfPresent(Int.self, forKey: .pasteboardChangeCount)
            ?? defaults.pasteboardChangeCount
        toggleHotKey = try container.decodeIfPresent(KeyCombo.self, forKey: .toggleHotKey)
            ?? defaults.toggleHotKey
        maxHistory = try container.decodeIfPresent(Int.self, forKey: .maxHistory)
            ?? defaults.maxHistory
        showsRichText = try container.decodeIfPresent(Bool.self, forKey: .showsRichText)
            ?? defaults.showsRichText
        pastesRichText = try container.decodeIfPresent(Bool.self, forKey: .pastesRichText)
            ?? defaults.pastesRichText
        maxItemSizeMB = try container.decodeIfPresent(Int.self, forKey: .maxItemSizeMB)
            ?? defaults.maxItemSizeMB
        requiresPasswordAuthentication = try container.decodeIfPresent(Bool.self, forKey: .requiresPasswordAuthentication)
            ?? defaults.requiresPasswordAuthentication
        passwordAuthGraceMinutes = try container.decodeIfPresent(Int.self, forKey: .passwordAuthGraceMinutes)
            ?? defaults.passwordAuthGraceMinutes
        passwordClipboardClearSeconds = try container.decodeIfPresent(Int.self, forKey: .passwordClipboardClearSeconds)
            ?? defaults.passwordClipboardClearSeconds
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(panelPosition, forKey: .panelPosition)
        try container.encode(pasteboardChangeCount, forKey: .pasteboardChangeCount)
        try container.encode(toggleHotKey, forKey: .toggleHotKey)
        try container.encode(maxHistory, forKey: .maxHistory)
        try container.encode(showsRichText, forKey: .showsRichText)
        try container.encode(pastesRichText, forKey: .pastesRichText)
        try container.encode(maxItemSizeMB, forKey: .maxItemSizeMB)
        try container.encode(requiresPasswordAuthentication, forKey: .requiresPasswordAuthentication)
        try container.encode(passwordAuthGraceMinutes, forKey: .passwordAuthGraceMinutes)
        try container.encode(passwordClipboardClearSeconds, forKey: .passwordClipboardClearSeconds)
    }

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

#if DEBUG
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
#endif

extension Settings: Equatable {
    
}

//
//  Settings.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
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
        passwordClipboardClearSeconds: Int,
        isCapturePaused: Bool,
        excludedBundleIds: [String],
        retentionDays: Int,
        panelTextSize: TextSizePreference,
        panelEdgeWidth: Double,
        panelEdgeHeight: Double,
        panelCenterWidth: Double,
        panelCenterHeight: Double
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
        self.isCapturePaused = isCapturePaused
        self.excludedBundleIds = excludedBundleIds
        self.retentionDays = retentionDays
        self.panelTextSize = panelTextSize
        self.panelEdgeWidth = panelEdgeWidth
        self.panelEdgeHeight = panelEdgeHeight
        self.panelCenterWidth = panelCenterWidth
        self.panelCenterHeight = panelCenterHeight
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
        passwordClipboardClearSeconds: 90,
        isCapturePaused: false,
        excludedBundleIds: [],
        retentionDays: 0,
        panelTextSize: .m,
        panelEdgeWidth: 480,
        panelEdgeHeight: 360,
        panelCenterWidth: 0,
        panelCenterHeight: 0
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

    /// When true, pasteboard changes are ignored (T31).
    var isCapturePaused: Bool

    /// User-managed apps whose clipboard changes are ignored (T33).
    var excludedBundleIds: [String]

    /// Auto-delete unpinned items older than N days; `0` disables (T34).
    var retentionDays: Int

    /// Compact / default / large / extra-large panel row typography (U02).
    var panelTextSize: TextSizePreference

    /// Edge panel width/height and center size (0 = 60% of visible) (U07).
    var panelEdgeWidth: Double
    var panelEdgeHeight: Double
    var panelCenterWidth: Double
    var panelCenterHeight: Double

    var panelSizes: PanelSizeState {
        PanelSizeState(
            edgeWidth: CGFloat(panelEdgeWidth),
            edgeHeight: CGFloat(panelEdgeHeight),
            centerWidth: CGFloat(panelCenterWidth),
            centerHeight: CGFloat(panelCenterHeight)
        )
    }

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
        case isCapturePaused
        case excludedBundleIds
        case retentionDays
        case panelTextSize
        case panelEdgeWidth
        case panelEdgeHeight
        case panelCenterWidth
        case panelCenterHeight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings.default

        var legacyCenterFraction: Double?
        if let raw = try container.decodeIfPresent(Int.self, forKey: .panelPosition) {
            let migrated = PanelFrameCalculator.migrateLegacyPosition(rawValue: raw)
            panelPosition = migrated.0
            if let fraction = migrated.1 {
                legacyCenterFraction = Double(fraction)
            }
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
        isCapturePaused = try container.decodeIfPresent(Bool.self, forKey: .isCapturePaused)
            ?? defaults.isCapturePaused
        excludedBundleIds = try container.decodeIfPresent([String].self, forKey: .excludedBundleIds)
            ?? defaults.excludedBundleIds
        retentionDays = try container.decodeIfPresent(Int.self, forKey: .retentionDays)
            ?? defaults.retentionDays
        panelTextSize = try container.decodeIfPresent(TextSizePreference.self, forKey: .panelTextSize)
            ?? defaults.panelTextSize
        panelEdgeWidth = try container.decodeIfPresent(Double.self, forKey: .panelEdgeWidth)
            ?? defaults.panelEdgeWidth
        panelEdgeHeight = try container.decodeIfPresent(Double.self, forKey: .panelEdgeHeight)
            ?? defaults.panelEdgeHeight
        if let width = try container.decodeIfPresent(Double.self, forKey: .panelCenterWidth),
           let height = try container.decodeIfPresent(Double.self, forKey: .panelCenterHeight) {
            panelCenterWidth = width
            panelCenterHeight = height
        } else if let fraction = legacyCenterFraction {
            // Negative = fraction of visible frame (legacy 8/4/5/6 centers).
            panelCenterWidth = -fraction
            panelCenterHeight = -fraction
        } else {
            panelCenterWidth = defaults.panelCenterWidth
            panelCenterHeight = defaults.panelCenterHeight
        }
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
        try container.encode(isCapturePaused, forKey: .isCapturePaused)
        try container.encode(excludedBundleIds, forKey: .excludedBundleIds)
        try container.encode(retentionDays, forKey: .retentionDays)
        try container.encode(panelTextSize, forKey: .panelTextSize)
        try container.encode(panelEdgeWidth, forKey: .panelEdgeWidth)
        try container.encode(panelEdgeHeight, forKey: .panelEdgeHeight)
        try container.encode(panelCenterWidth, forKey: .panelCenterWidth)
        try container.encode(panelCenterHeight, forKey: .panelCenterHeight)
    }

    // MARK: - State Binding Methods
    
    func bindPanelPositionTo(state: BehaviorRelay<PanelPosition>) -> Disposable {
        return state.bind { x in
            SettingsPersistence.apply { $0.panelPosition = x }
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

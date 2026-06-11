import Foundation

// Typed accessors for String Catalog keys — UI follows the system locale (EN/RU in Localizable.xcstrings).

enum L10n {

    private static func tr(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }

    // MARK: - Menu

    static var menuAbout: String { tr("menu.about") }
    static var menuHelp: String { tr( "menu.help") }
    static var menuPreferences: String { tr( "menu.preferences") }
    static var menuToggleWindow: String { tr( "menu.toggle_window") }
    static var menuLaunchAtLogin: String { tr( "menu.launch_at_login") }
    static var menuDeleteSelected: String { tr( "menu.delete_selected") }
    static var menuClearHistory: String { tr( "menu.clear_history") }
    static var menuClearAll: String { tr( "menu.clear_all") }
    static var menuPosition: String { tr( "menu.position") }
    static var menuQuit: String { tr( "menu.quit") }

    // MARK: - Tabs

    static var tabHistory: String { tr( "tab.history") }
    static var tabFavorites: String { tr( "tab.favorites") }
    static var tabPasswords: String { tr( "tab.passwords") }

    // MARK: - Panel position

    static var positionRight: String { tr( "position.right") }
    static var positionLeft: String { tr( "position.left") }
    static var positionTop: String { tr( "position.top") }
    static var positionBottom: String { tr( "position.bottom") }
    static var positionCenterExtraSmall: String { tr( "position.center_extra_small") }
    static var positionCenterSmall: String { tr( "position.center_small") }
    static var positionCenterMedium: String { tr( "position.center_medium") }
    static var positionCenterLarge: String { tr( "position.center_large") }
    static var positionFullScreen: String { tr( "position.full_screen") }

    // MARK: - Context menu

    static var contextAddToFavorites: String { tr( "context.add_favorites") }
    static var contextRemoveFromFavorites: String { tr( "context.remove_favorites") }
    static var contextDelete: String { tr( "context.delete") }
    static var contextCopyLogin: String { tr( "context.copy_login") }
    static var contextCopyPassword: String { tr( "context.copy_password") }
    static var contextEdit: String { tr( "context.edit") }
    static var contextRemoveFromPasswords: String { tr( "context.remove_from_passwords") }
    static var contextSaveToPasswords: String { tr( "context.save_to_passwords") }

    // MARK: - Counts

    static func countItems(_ count: Int) -> String {
        String(format: tr( "count.items"), count)
    }

    static func countMatches(_ count: Int) -> String {
        String(format: tr( "count.matches"), count)
    }

    static var countFavoriteOne: String { tr( "count.favorite_one") }

    static func countFavorites(_ count: Int) -> String {
        String(format: tr( "count.favorites"), count)
    }

    static var countPasswordOne: String { tr( "count.password_one") }

    static func countPasswords(_ count: Int) -> String {
        String(format: tr( "count.passwords"), count)
    }

    static func countPinnedLimit(current: Int, max: Int) -> String {
        String(format: tr( "count.pinned_limit"), current, max)
    }

    // MARK: - Empty state

    static var emptyFavorites: String { tr( "empty.favorites") }
    static var emptyPasswords: String { tr( "empty.passwords") }

    // MARK: - Password prompts

    static var passwordSaveTitle: String { tr( "password.save_title") }
    static var passwordSaveMessage: String { tr( "password.save_message") }
    static var passwordEditTitle: String { tr( "password.edit_title") }
    static var passwordEditMessage: String { tr( "password.edit_message") }
    static var passwordFieldComment: String { tr( "password.field_comment") }
    static var passwordFieldLogin: String { tr( "password.field_login") }

    // MARK: - Common

    static var commonSave: String { tr( "common.save") }
    static var commonCancel: String { tr( "common.cancel") }
    static var commonOK: String { tr( "common.ok") }
    static var commonQuit: String { tr( "common.quit") }
    static var commonOpenSettings: String { tr( "common.open_settings") }
    static var commonOpenKeychainAccess: String { tr( "common.open_keychain_access") }
    static var commonStartFresh: String { tr( "common.start_fresh") }

    // MARK: - Search

    static var searchPlaceholder: String { tr( "search.placeholder") }

    // MARK: - Accessibility alerts

    static var accessibilityRequiredTitle: String { tr( "accessibility.required_title") }
    static var accessibilityRequiredBody: String { tr( "accessibility.required_body") }
    static var accessibilityRequiredUnsignedSuffix: String { tr( "accessibility.required_unsigned_suffix") }
    static var accessibilityPasteBlockedTitle: String { tr( "accessibility.paste_blocked_title") }
    static var accessibilityPasteBlockedBody: String { tr( "accessibility.paste_blocked_body") }

    // MARK: - Install

    static var installTransientTitle: String { tr( "install.transient_title") }
    static var installTransientBody: String { tr( "install.transient_body") }

    // MARK: - Encryption / keychain

    static var encryptionDecryptTitle: String { tr( "encryption.decrypt_title") }
    static var encryptionDecryptBody: String { tr( "encryption.decrypt_body") }
    static var encryptionKeyTitle: String { tr( "encryption.key_title") }
    static var encryptionKeychainUnlock: String { tr( "encryption.keychain_unlock") }

    static func encryptionKeychainDenied(account: String) -> String {
        String(format: tr( "encryption.keychain_denied"), account)
    }

    static func encryptionKeychainEntitlement(status: Int32) -> String {
        String(format: tr( "encryption.keychain_entitlement"), status)
    }

    static func encryptionKeychainGeneric(status: Int32) -> String {
        String(format: tr( "encryption.keychain_generic"), status)
    }

    // MARK: - Storyboard load failure

    static func storyboardCorruptedTitle(appName: String) -> String {
        String(format: tr( "storyboard.corrupted_title"), appName)
    }

    static func storyboardCorruptedBody(identifier: String, storyboardName: String) -> String {
        String(format: tr( "storyboard.corrupted_body"), identifier, storyboardName)
    }

    // MARK: - Welcome

    static var welcomeTitle: String { tr( "welcome.title") }
    static var welcomeBody: String { tr( "welcome.body") }
    static var welcomeAllowAccess: String { tr( "welcome.allow_access") }

    // MARK: - Help

    static var helpWindowTitle: String { tr("help.window_title") }
    static var helpWaitingTitle: String { tr( "help.waiting_title") }
    static var helpWaitingBody: String { tr( "help.waiting_body") }
    static var helpHowToUseTitle: String { tr( "help.how_to_use_title") }
    static var helpInstructionsBody: String { tr( "help.instructions_body") }

    // MARK: - Settings

    static var settingsGeneral: String { tr( "settings.general") }
    static var settingsHotKey: String { tr( "settings.hot_key") }
    static var settingsMaxItemsLabel: String { tr( "settings.max_items_label") }
    static var settingsRichTextLabel: String { tr( "settings.rich_text_label") }
    static var settingsShowsRichText: String { tr( "settings.shows_rich_text") }
    static var settingsPastesRichText: String { tr( "settings.pastes_rich_text") }
    static var settingsHotkeyHint: String { tr( "settings.hotkey_hint") }

    // MARK: - About

    static func aboutVersion(version: String, build: String) -> String {
        String(format: tr( "about.version"), version, build)
    }

    static var aboutInfoBody: String { tr( "about.info_body") }

    // MARK: - Preview

    static var previewClickToReveal: String { tr( "preview.click_to_reveal") }

    // MARK: - Alerts

    static var alertClearHistoryTitle: String { tr( "alert.clear_history.title") }
    static var alertClearHistoryMessage: String { tr( "alert.clear_history.message") }

    // MARK: - Hot key

    static var hotkeyUnknownKey: String { tr( "hotkey.unknown_key") }
}

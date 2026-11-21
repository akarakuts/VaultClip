import Foundation

// Typed accessors for String Catalog keys — UI follows the system locale (all macOS app languages in Localizable.xcstrings).

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
    static var menuPauseCapture: String { tr("menu.pause_capture") }
    static var menuResumeCapture: String { tr("menu.resume_capture") }
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
    static var positionCenter: String { tr("position.center") }
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
    static var contextCopyURL: String { tr( "context.copy_url") }
    static var contextOpenURL: String { tr( "context.open_url") }
    static var contextCopyPassword: String { tr( "context.copy_password") }
    static var contextEdit: String { tr( "context.edit") }
    static var contextRemoveFromPasswords: String { tr( "context.remove_from_passwords") }
    static var contextSaveToPasswords: String { tr( "context.save_to_passwords") }

    // MARK: - Counts

    static func countItems(_ count: Int) -> String {
        String.localizedStringWithFormat(tr("count.items"), count)
    }

    static func countMatches(_ count: Int) -> String {
        String.localizedStringWithFormat(tr("count.matches"), count)
    }

    static var countFavoriteOne: String { tr( "count.favorite_one") }

    static func countFavorites(_ count: Int) -> String {
        String.localizedStringWithFormat(tr("count.favorites"), count)
    }

    static var countPasswordOne: String { tr( "count.password_one") }

    static func countPasswords(_ count: Int) -> String {
        String.localizedStringWithFormat(tr("count.passwords"), count)
    }

    static func countPinnedLimit(current: Int, max: Int) -> String {
        String(format: tr( "count.pinned_limit"), current, max)
    }

    // MARK: - Empty state

    static var emptyFavorites: String { tr( "empty.favorites") }
    static var emptyPasswords: String { tr( "empty.passwords") }
    static var emptyHistoryTitle: String { tr("empty.history.title") }
    static var emptyHistoryBody: String { tr("empty.history.body") }
    static var emptyHistoryPausedTitle: String { tr("empty.history.paused_title") }
    static var emptyHistoryPausedBody: String { tr("empty.history.paused_body") }
    static var emptyHistoryResume: String { tr("empty.history.resume") }
    static var emptyFavoritesTitle: String { tr("empty.favorites.title") }
    static var emptyFavoritesBody: String { tr("empty.favorites.body") }
    static var emptyPasswordsTitle: String { tr("empty.passwords.title") }
    static var emptyPasswordsBodyManagers: String { tr("empty.passwords.body_managers") }
    static var emptyPasswordsBodySave: String { tr("empty.passwords.body_save") }
    static func emptyNoResultsTitle(_ query: String) -> String {
        String(format: tr("empty.no_results.title"), query)
    }
    static func emptyNoResultsOtherTab(count: Int, tab: String) -> String {
        String(format: tr("empty.no_results.other_tab"), count, tab)
    }
    static var emptyClearFilters: String { tr("empty.clear_filters") }
    static var emptyGo: String { tr("empty.go") }

    /// Shown in the history list while the encrypted store loads on launch.
    static var historyLoading: String { tr( "history.loading") }

    // MARK: - Status bar

    static var statusLoading: String { tr("status.loading") }
    static func statusFoundOf(visible: Int, total: Int) -> String {
        String(format: tr("status.found_of"), visible, total)
    }
    static func statusSelected(_ count: Int) -> String {
        String(format: tr("status.selected"), count)
    }
    static var hintPaste: String { tr("hint.paste") }
    static var hintActions: String { tr("hint.actions") }
    static var hintKeys: String { tr("hint.keys") }
    static func hintPasteCount(_ count: Int) -> String {
        String(format: tr("hint.paste_count"), count)
    }
    static var hintClearSelection: String { tr("hint.clear_selection") }
    static var hintPasteEdit: String { tr("hint.paste_edit") }
    static var hintSaveEdit: String { tr("hint.save_edit") }
    static var hintCancel: String { tr("hint.cancel") }

    // MARK: - Preview

    static var previewNothingSelected: String { tr("preview.nothing_selected") }
    static var previewKindText: String { tr("preview.kind.text") }
    static var previewKindImage: String { tr("preview.kind.image") }
    static var previewKindColor: String { tr("preview.kind.color") }
    static var previewKindLink: String { tr("preview.kind.link") }
    static var previewKindPassword: String { tr("preview.kind.password") }
    static func previewKindFiles(_ count: Int) -> String {
        String(format: tr("preview.kind.files"), count)
    }
    static func previewChars(_ count: Int) -> String {
        String(format: tr("preview.chars"), count)
    }
    static var previewFileMissing: String { tr("preview.file_missing") }
    static var previewLogin: String { tr("preview.login") }
    static var previewOpen: String { tr("preview.open") }
    static var previewCancelEdit: String { tr("preview.cancel_edit") }
    static var previewPasteEdit: String { tr("preview.paste_edit") }
    static func previewMetaApp(_ name: String) -> String {
        String(format: tr("preview.meta.app"), name)
    }
    static func previewMetaCopied(_ relative: String) -> String {
        String(format: tr("preview.meta.copied"), relative)
    }
    static func previewMetaUsed(_ relative: String) -> String {
        String(format: tr("preview.meta.used"), relative)
    }
    static func previewMetaSize(_ size: String) -> String {
        String(format: tr("preview.meta.size"), size)
    }

    // MARK: - Password prompts

    static var passwordSaveTitle: String { tr( "password.save_title") }
    static var passwordSaveMessage: String { tr( "password.save_message") }
    static var passwordEditTitle: String { tr( "password.edit_title") }
    static var passwordEditMessage: String { tr( "password.edit_message") }
    static var passwordFieldComment: String { tr( "password.field_comment") }
    static var passwordFieldLogin: String { tr( "password.field_login") }
    static var passwordFieldURL: String { tr( "password.field_url") }

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
    static var searchPlaceholderPasswords: String { tr("search.placeholder.passwords") }
    static var searchTooltip: String { tr("search.tooltip") }
    static var searchTooltipPasswords: String { tr("search.tooltip.passwords") }

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

    static func encryptionQuarantineBody(count: Int) -> String {
        String(format: tr("encryption.quarantine_body"), count)
    }
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
    static var settingsPrivacy: String { tr("settings.privacy") }
    static var settingsPrivacyAdd: String { tr("settings.privacy.add") }
    static var settingsPrivacyRemove: String { tr("settings.privacy.remove") }
    static var settingsRetention: String { tr("settings.retention") }
    static var settingsRetentionNever: String { tr("settings.retention.never") }
    static func settingsRetentionDays(_ days: Int) -> String { String(format: tr("settings.retention.days"), days) }
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
    static var alertReduceHistoryTitle: String { tr("alert.reduce_history.title") }
    static func alertReduceHistoryMessage(_ count: Int) -> String {
        String(format: tr("alert.reduce_history.message"), count)
    }
    static var commonContinue: String { tr("common.continue") }
    static var passwordAuthReason: String { tr("password.auth.reason") }
    static var settingsPasswordAuth: String { tr("settings.password_auth") }
    static var settingsPasswordAuthGrace: String { tr("settings.password_auth_grace") }
    static var settingsPasswordAuthGraceImmediate: String { tr("settings.password_auth_grace.immediate") }
    static func settingsPasswordAuthGraceMinutes(_ minutes: Int) -> String {
        String(format: tr("settings.password_auth_grace.minutes"), minutes)
    }
    static var alertErrorsTitle: String { tr("alert.errors.title") }
    static var alertOpenLogsFolder: String { tr("alert.errors.open_logs") }
    static func alertErrorsAggregated(count: Int, lastMessage: String) -> String {
        String(format: tr("alert.errors.aggregated"), locale: .current, arguments: [count, lastMessage])
    }
    static var searchLabelPDF: String { tr("search.label.pdf") }
    static var searchLabelImage: String { tr("search.label.image") }
    static var pdfDocument: String { tr("pdf.document") }
    static var pdfPageOne: String { tr("pdf.page.one") }
    static func pdfPageOther(_ count: Int) -> String { String(format: tr("pdf.page.other"), count) }
    static func pdfTitled(_ title: String, _ pages: String) -> String {
        String(format: tr("pdf.titled"), title, pages)
    }
    static var imageGeneric: String { tr("image.generic") }
    static func imageTyped(_ type: String) -> String { String(format: tr("image.typed"), type) }
    static var a11yTypeText: String { tr("a11y.type.text") }
    static var a11yTypePassword: String { tr("a11y.type.password") }
    static var a11yTypeImage: String { tr("a11y.type.image") }
    static var a11yTypePDF: String { tr("a11y.type.pdf") }
    static var a11yTypeColor: String { tr("a11y.type.color") }
    static var a11yTypeFile: String { tr("a11y.type.file") }
    static var settingsMaxItemSizeLabel: String { tr("settings.max_item_size.label") }
    static var settingsMaxItemSizeUnlimited: String { tr("settings.max_item_size.unlimited") }
    static func settingsMaxItemSizeMB(_ mb: Int) -> String {
        String(format: tr("settings.max_item_size.mb"), mb)
    }

    static var launchAtLoginNeedsApprovalTitle: String { tr("launch_at_login.needs_approval.title") }
    static var launchAtLoginNeedsApprovalBody: String { tr("launch_at_login.needs_approval.body") }
    static var launchAtLoginOpenSettings: String { tr("launch_at_login.open_settings") }

    // MARK: - Hot key

    static var hotkeyUnknownKey: String { tr( "hotkey.unknown_key") }
    static var hotkeyErrorNeedsModifier: String { tr("hotkey.error.needs_modifier") }
    static var hotkeyErrorSystemShortcut: String { tr("hotkey.error.system_shortcut") }
    static var hotkeyErrorPanelConflict: String { tr("hotkey.error.panel_conflict") }
    static var hotkeyErrorInvalidKey: String { tr("hotkey.error.invalid_key") }

    // MARK: - Panel commands (U03)

    static func commandTitle(for key: String) -> String { tr(key) }

    static var command_togglePanel: String { tr("command.togglePanel") }
    static var command_paste: String { tr("command.paste") }
    static var command_pastePlainText: String { tr("command.pastePlainText") }
    static var command_quickPaste1: String { tr("command.quickPaste1") }
    static var command_quickPaste2: String { tr("command.quickPaste2") }
    static var command_quickPaste3: String { tr("command.quickPaste3") }
    static var command_quickPaste4: String { tr("command.quickPaste4") }
    static var command_quickPaste5: String { tr("command.quickPaste5") }
    static var command_quickPaste6: String { tr("command.quickPaste6") }
    static var command_quickPaste7: String { tr("command.quickPaste7") }
    static var command_quickPaste8: String { tr("command.quickPaste8") }
    static var command_quickPaste9: String { tr("command.quickPaste9") }
    static var command_quickPaste0: String { tr("command.quickPaste0") }
    static var command_copy: String { tr("command.copy") }
    static var command_commandPalette: String { tr("command.commandPalette") }
    static var command_focusSearch: String { tr("command.focusSearch") }
    static var command_togglePreview: String { tr("command.togglePreview") }
    static var command_quickLook: String { tr("command.quickLook") }
    static var command_editBeforePaste: String { tr("command.editBeforePaste") }
    static var command_pasteEdit: String { tr("command.pasteEdit") }
    static var command_saveEdit: String { tr("command.saveEdit") }
    static var command_toggleFavorite: String { tr("command.toggleFavorite") }
    static var command_delete: String { tr("command.delete") }
    static var command_undoDelete: String { tr("command.undoDelete") }
    static var command_openLinkOrFile: String { tr("command.openLinkOrFile") }
    static var command_revealInFinder: String { tr("command.revealInFinder") }
    static var command_selectNext: String { tr("command.selectNext") }
    static var command_selectPrevious: String { tr("command.selectPrevious") }
    static var command_selectFirst: String { tr("command.selectFirst") }
    static var command_selectLast: String { tr("command.selectLast") }
    static var command_pageUp: String { tr("command.pageUp") }
    static var command_pageDown: String { tr("command.pageDown") }
    static var command_extendSelectionUp: String { tr("command.extendSelectionUp") }
    static var command_extendSelectionDown: String { tr("command.extendSelectionDown") }
    static var command_selectAll: String { tr("command.selectAll") }
    static var command_nextTab: String { tr("command.nextTab") }
    static var command_previousTab: String { tr("command.previousTab") }
    static var command_filterTypeAll: String { tr("command.filterTypeAll") }
    static var command_filterTypeText: String { tr("command.filterTypeText") }
    static var command_filterTypeLinks: String { tr("command.filterTypeLinks") }
    static var command_filterTypeImages: String { tr("command.filterTypeImages") }
    static var command_filterTypeFiles: String { tr("command.filterTypeFiles") }
    static var command_filterTypeColors: String { tr("command.filterTypeColors") }
    static var command_filterApp: String { tr("command.filterApp") }
    static var command_clearFilters: String { tr("command.clearFilters") }

    static var toastCopied: String { tr("toast.copied") }
    static var toastUndo: String { tr("toast.undo") }
    /// Esc once while the inline editor is dirty — next Esc discards.
    static var toastEditDiscardArmed: String { tr("toast.edit_discard_armed") }
    static var a11yHeaderFilter: String { tr("a11y.header_filter") }
    static var a11yHeaderPreview: String { tr("a11y.header_preview") }
    static var a11yHeaderMore: String { tr("a11y.header_more") }
    static func toastDeleted(_ count: Int) -> String { String(format: tr("toast.deleted"), count) }
    static func toastClipboardClearsIn(_ seconds: Int) -> String {
        String(format: tr("toast.clipboard_clears_in"), seconds)
    }

    // MARK: - Settings UI (SwiftUI tabs)

    static var settingsLaunchAtLoginHint: String { tr("settings.launch_at_login_hint") }
    static var settingsStatusClick: String { tr("settings.status_click") }
    static var settingsStatusClickPanel: String { tr("settings.status_click.panel") }
    static var settingsStatusClickMenu: String { tr("settings.status_click.menu") }
    static var settingsShowRecentMenu: String { tr("settings.show_recent_menu") }
    static func settingsRecentCount(_ n: Int) -> String { String(format: tr("settings.recent_count"), n) }
    static var settingsTabPanel: String { tr("settings.tab.panel") }
    static var settingsTabPaste: String { tr("settings.tab.paste") }
    static var settingsTabHistory: String { tr("settings.tab.history") }
    static var settingsWidth: String { tr("settings.width") }
    static var settingsHeight: String { tr("settings.height") }
    static var settingsTextSize: String { tr("settings.text_size") }
    static var settingsMonospaced: String { tr("settings.monospaced") }
    static var settingsGroupByDate: String { tr("settings.group_by_date") }
    static var settingsShowFilterBar: String { tr("settings.show_filter_bar") }
    static var settingsShowKeyHints: String { tr("settings.show_key_hints") }
    static var settingsShowPreview: String { tr("settings.show_preview") }
    static var settingsPreviewPlacement: String { tr("settings.preview_placement") }
    static var settingsPreviewAutomatic: String { tr("settings.preview.automatic") }
    static var settingsPreviewTrailing: String { tr("settings.preview.trailing") }
    static var settingsPreviewBottom: String { tr("settings.preview.bottom") }
    static var settingsResetFiltersOnClose: String { tr("settings.reset_filters_on_close") }
    static var settingsReopenLastTab: String { tr("settings.reopen_last_tab") }
    static var settingsSelectSecondItem: String { tr("settings.select_second_item") }
    static var settingsMultiPasteSeparator: String { tr("settings.multi_paste_separator") }
    static var settingsSepNewline: String { tr("settings.sep.newline") }
    static var settingsSepBlankLine: String { tr("settings.sep.blank_line") }
    static var settingsSepSpace: String { tr("settings.sep.space") }
    static var settingsSepComma: String { tr("settings.sep.comma") }
    static var settingsSepTab: String { tr("settings.sep.tab") }
    static var settingsClearClipboardAfterPassword: String { tr("settings.clear_clipboard_after_password") }
    static var settingsOff: String { tr("settings.off") }
    static func settingsDeleteOlderThan(_ days: String) -> String {
        String(format: tr("settings.delete_older_than"), days)
    }
    static var settingsRetentionLastUsedHint: String { tr("settings.retention_last_used_hint") }
    static var settingsRequireAuth: String { tr("settings.require_auth") }
    static func settingsAuthGrace(_ minutes: Int) -> String {
        String(format: tr("settings.auth_grace"), minutes)
    }
    static var settingsAuthGraceHint: String { tr("settings.auth_grace_hint") }
    static var settingsHideFromCapture: String { tr("settings.hide_from_capture") }
    static var settingsHideFromCaptureHint: String { tr("settings.hide_from_capture_hint") }
    static var settingsExcludedApps: String { tr("settings.excluded_apps") }
    static var settingsExcludedAppsHint: String { tr("settings.excluded_apps_hint") }
    static var settingsAlwaysExcluded: String { tr("settings.always_excluded") }
    static var settingsHotkeyListHint: String { tr("settings.hotkey_list_hint") }
    static var settingsHotkeyPress: String { tr("settings.hotkey_press") }
    static var settingsHotkeyCaptureHint: String { tr("settings.hotkey_capture_hint") }
    static var settingsPanelCommands: String { tr("settings.panel_commands") }
    static var settingsMin: String { tr("settings.min") }

    static var cheatFilterPlaceholder: String { tr("cheat.filter_placeholder") }
    static var cheatGroupItem: String { tr("cheat.group.item") }
    static var cheatGroupView: String { tr("cheat.group.view") }
    static var cheatGroupFilter: String { tr("cheat.group.filter") }
    static var cheatGroupApp: String { tr("cheat.group.app") }
    static var cheatGroupWindow: String { tr("cheat.group.window") }
    static var paletteFilterPlaceholder: String { tr("palette.filter_placeholder") }
    static var paletteGroupSelection: String { tr("palette.group.selection") }
    static var paletteGroupView: String { tr("palette.group.view") }
    static var paletteGroupFilters: String { tr("palette.group.filters") }
    static var paletteGroupApp: String { tr("palette.group.app") }
    static var dateToday: String { tr("date.today") }
    static var dateYesterday: String { tr("date.yesterday") }
    static var dateLast7: String { tr("date.last7") }
    static var dateLast30: String { tr("date.last30") }
    static var relativeJustNow: String { tr("relative.just_now") }
    static func relativeMinutes(_ m: Int) -> String { String(format: tr("relative.minutes"), m) }
    static func relativeHours(_ h: Int) -> String { String(format: tr("relative.hours"), h) }
    static func relativeDays(_ d: Int) -> String { String(format: tr("relative.days"), d) }
    static var rowKindPassword: String { tr("row.kind.password") }
    static var rowKindFile: String { tr("row.kind.file") }
    static var rowKindImage: String { tr("row.kind.image") }
    static var rowMetaLink: String { tr("row.meta.link") }
    static func rowMetaFile(_ count: Int) -> String {
        String(format: tr(count == 1 ? "row.meta.file_one" : "row.meta.file_other"), count)
    }
    static func rowMetaLines(_ count: Int) -> String { String(format: tr("row.meta.lines"), count) }
    static func rowMetaChars(_ formatted: String) -> String {
        String(format: tr("row.meta.chars"), formatted)
    }
    static func rowAndMore(_ count: Int) -> String { String(format: tr("row.and_more"), count) }
    static func rowPdfPages(_ count: Int) -> String { String(format: tr("row.pdf_pages"), count) }

    static var filterAllApps: String { tr("filter.allApps") }
    static var filterUnknownSource: String { tr("filter.unknownSource") }
    static var filterTypeAll: String { tr("filter.typeAll") }
    static var filterTypeText: String { tr("filter.typeText") }
    static var filterTypeLinks: String { tr("filter.typeLinks") }
    static var filterTypeImages: String { tr("filter.typeImages") }
    static var filterTypeFiles: String { tr("filter.typeFiles") }
    static var filterTypeColors: String { tr("filter.typeColors") }
    static var command_textSizeIncrease: String { tr("command.textSizeIncrease") }
    static var command_textSizeDecrease: String { tr("command.textSizeDecrease") }
    static var command_cheatSheet: String { tr("command.cheatSheet") }
    static var command_openSettings: String { tr("command.openSettings") }
    static var command_panelPositionLeft: String { tr("command.panelPositionLeft") }
    static var command_panelPositionRight: String { tr("command.panelPositionRight") }
    static var command_panelPositionUp: String { tr("command.panelPositionUp") }
    static var command_panelPositionDown: String { tr("command.panelPositionDown") }
    static var command_closePanel: String { tr("command.closePanel") }
}

//
// HistoryViewController+Delegates — table, tab bar, and search field delegates.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

extension HistoryViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension HistoryViewController: HistoryTableViewDelegate {
    func historyTableView(_ historyTableView: HistoryTableView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }

    func historyTableView(_ historyTableView: HistoryTableView, didMoveItem from: Int, to: Int) {
        historyPanel.move(displayedFrom: from, to: to)
        selected.accept(to)
    }

    func historyTableView(_ historyTableView: HistoryTableView, toggleFavoriteAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        _ = historyPanel.toggleFavorite(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, saveToPasswordsAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        let item = historyPanel.items[row]
        guard let fields = PasswordEntryPrompt.run(
            title: L10n.passwordSaveTitle,
            message: L10n.passwordSaveMessage
        ) else { return }
        historyPanel.saveToPasswords(item: item, comment: fields.comment, login: fields.login, url: fields.url)
    }

    func historyTableView(_ historyTableView: HistoryTableView, removeFromPasswordsAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.removeFromPasswords(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, editPasswordEntryAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        let item = historyPanel.items[row]
        guard let fields = PasswordEntryPrompt.run(
            title: L10n.passwordEditTitle,
            message: L10n.passwordEditMessage,
            initialComment: item.passwordComment,
            initialLogin: item.passwordLogin,
            initialURL: item.passwordURL
        ) else { return }
        historyPanel.editPasswordEntry(item: item, comment: fields.comment, login: fields.login, url: fields.url)
    }

    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordLoginAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.copyLogin(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordValueAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.copyPassword(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordURLAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.copyPasswordURL(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, openPasswordURLAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.openPasswordURL(item: historyPanel.items[row])
    }

    func historyTableView(_ historyTableView: HistoryTableView, deleteItemAt row: Int) {
        selected.accept(historyPanel.delete(displayedIndex: row))
    }
}

extension HistoryViewController: HistoryTabBarViewDelegate {
    func historyTabBarView(_ tabBar: HistoryTabBarView, didSelect mode: HistoryListMode) {
        listMode.accept(mode)
    }
}

//
//  HistoryPanel.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HistoryPanel {

    let history: History
    var items: [HistoryItem]

    let pasteboard: NSPasteboard
    private let settings: () -> Settings
    private let isPanelShown: () -> Bool

    /// Change counts produced by VaultClip's own paste actions (P8.3): the monitor skips
    /// them even when the source app is unknown/denylisted, instead of re-inserting.
    /// Internal-set for tests; production only mutates through `markSelfWrite`.
    static var lastSelfWriteChangeCount: Int?

    private static func markSelfWrite(_ changeCount: Int) {
        lastSelfWriteChangeCount = changeCount
    }

    init(
        history: History,
        items: [HistoryItem],
        pasteboard: NSPasteboard = .general,
        settings: @escaping () -> Settings = { SettingsPersistence.current() },
        isPanelShown: @escaping () -> Bool = { AppEnvironment.shared.state.isHistoryPanelShown.value }
    ) {
        self.history = history
        self.items = items
        self.pasteboard = pasteboard
        self.settings = settings
        self.isPanelShown = isPanelShown
    }

    func paste(item: HistoryItem, plainTextOnly: Bool = false) {
        guard history.index(of: item) != nil else { return }
        let perform = { [weak self] in
            guard let self, let index = self.history.index(of: item) else { return }
            if plainTextOnly {
                guard let plain = Self.plainTextForPaste(from: item) else { return }
                self.history.moveItem(at: index, to: 0)
                item.lastUsedAt = Date()
                let changeCount = PasteboardWriter.writeString(plain, to: self.pasteboard, concealed: item.isPassword)
                HistoryPanel.markSelfWrite(changeCount)
                self.history.noteClipboardItemId(item.fsId)
                self.history.recordPasteboardChange(withCount: changeCount)
                if item.isPassword {
                    PasswordClipboardClearer.shared.scheduleClear(afterWritingChangeCount: changeCount, pasteboard: self.pasteboard)
                }
                self.scheduleSimulatedPaste()
                return
            }
            self.history.moveItem(at: index, to: 0)
            item.lastUsedAt = Date()
            // Per-item rich-text decision from current settings (D5).
            item.pastesRichText = self.settings().pastesRichText
            let changeCount = item.write(to: self.pasteboard)
            HistoryPanel.markSelfWrite(changeCount)
            self.history.noteClipboardItemId(item.fsId)
            self.history.recordPasteboardChange(withCount: changeCount)
            if item.isPassword {
                PasswordClipboardClearer.shared.scheduleClear(afterWritingChangeCount: changeCount, pasteboard: self.pasteboard)
            }
            self.scheduleSimulatedPaste()
        }
        if item.isPassword {
            PasswordAccessGate.shared.authorize { ok in
                if ok { perform() }
            }
        } else {
            perform()
        }
    }

    /// Plain / RTF / HTML / URL text for Shift+Return paste (T32).
    static func plainTextForPaste(from item: HistoryItem) -> String? {
        if let plain = item.getPlainString(), !plain.isEmpty { return plain }
        if let rtf = item.data(forType: .rtf),
           let attr = NSAttributedString(rtf: rtf, documentAttributes: nil),
           !attr.string.isEmpty {
            return attr.string
        }
        if let html = item.data(forType: .html),
           let raw = String(data: html, encoding: .utf8) {
            let stripped = HistoryItemText.stripHTMLTagsForSearch(raw)
            if !stripped.isEmpty { return stripped }
        }
        if let url = item.getUrl() {
            return url.absoluteString
        }
        return nil
    }
    
    func paste(displayedIndex: Int) {
        guard displayedIndex >= 0, displayedIndex < items.count else { return }
        paste(item: items[displayedIndex])
    }

    /// ⌘C: put the item on the pasteboard without pasting or reordering; passwords go through the gate.
    func copyToClipboard(item: HistoryItem) {
        let perform = { [weak self] in
            guard let self else { return }
            item.pastesRichText = self.settings().pastesRichText
            item.lastUsedAt = Date()
            let changeCount = item.write(to: self.pasteboard)
            HistoryPanel.markSelfWrite(changeCount)
            self.history.noteClipboardItemId(item.fsId)
            self.history.recordPasteboardChange(withCount: changeCount)
            if item.isPassword {
                PasswordClipboardClearer.shared.scheduleClear(afterWritingChangeCount: changeCount, pasteboard: self.pasteboard)
            }
        }
        if item.isPassword {
            PasswordAccessGate.shared.authorize { ok in
                if ok { perform() }
            }
        } else {
            perform()
        }
    }

    /// Copies plain text (multi-select ⌘C) without pasting.
    func copyText(_ text: String) {
        copyStringToClipboard(text, concealed: false)
    }

    /// Multi-paste joined text without reordering history; updates `lastUsedAt` (U16).
    func multiPasteJoined(_ text: String, items: [HistoryItem]) {
        let changeCount = PasteboardWriter.writeString(text, to: pasteboard, concealed: false)
        HistoryPanel.markSelfWrite(changeCount)
        history.recordPasteboardChange(withCount: changeCount)
        let now = Date()
        for item in items where !item.isPassword {
            item.lastUsedAt = now
        }
        scheduleSimulatedPaste()
    }

    /// Multi-paste discrete file/image items without reordering (U16).
    func multiPasteDiscrete(_ items: [HistoryItem]) {
        let writers = items.filter { !$0.isPassword }
        guard !writers.isEmpty else { return }
        _ = pasteboard.prepareForNewContents(with: [])
        pasteboard.writeObjects(writers)
        let changeCount = pasteboard.changeCount
        HistoryPanel.markSelfWrite(changeCount)
        history.recordPasteboardChange(withCount: changeCount)
        let now = Date()
        for item in writers {
            item.lastUsedAt = now
        }
        scheduleSimulatedPaste()
    }
    
    /// Simulates ⌘V in the previously focused app after the history panel closes.
    private func scheduleSimulatedPaste() {
        DispatchQueue.main.async {
            self.performSimulatedPaste(startedAt: Date())
        }
    }

    private func performSimulatedPaste(startedAt: Date) {
        let elapsed = Date().timeIntervalSince(startedAt)

        if isPanelShown() {
            if elapsed < 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.performSimulatedPaste(startedAt: startedAt)
                }
            }
            return
        }

        let focusDelay: TimeInterval = 0.12
        if elapsed < focusDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + (focusDelay - elapsed)) {
                self.performSimulatedPaste(startedAt: startedAt)
            }
            return
        }

        guard Helper.isControlGranted(showPopup: false) else {
            Helper.notifyPasteBlockedIfNeeded()
            return
        }
        Helper.pressCommandV()
    }
    
    /// Returns the next row index to select in the displayed list.
    func delete(item: HistoryItem) -> Int? {
        guard let displayedIndex = items.firstIndex(where: { $0.fsId == item.fsId }) else { return nil }
        let matchesClipboard = item.fsId == history.currentClipboardItemId
            && pasteboard.changeCount == history.lastRecordedChangeCount
        history.deleteItem(withId: item.fsId)

        // Clear the system pasteboard only when this item is what is currently on it (T15).
        if matchesClipboard {
            let newChangeCount = pasteboard.clearContents()
            HistoryPanel.markSelfWrite(newChangeCount)
            history.clearCurrentClipboardItemId()
            history.recordPasteboardChange(withCount: newChangeCount)
        }

        if displayedIndex < items.count - 1 {
            return displayedIndex
        }
        if displayedIndex > 0 {
            return displayedIndex - 1
        }
        return nil
    }
    
    func delete(displayedIndex: Int) -> Int? {
        guard displayedIndex >= 0, displayedIndex < items.count else { return nil }
        return delete(item: items[displayedIndex])
    }
    
    func move(displayedFrom: Int, to displayedTo: Int) {
        guard displayedFrom >= 0, displayedFrom < items.count,
              displayedTo >= 0, displayedTo < items.count,
              displayedFrom != displayedTo else { return }
        
        let fromItem = items[displayedFrom]
        let toItem = items[displayedTo]
        guard let from = history.index(of: fromItem), let to = history.index(of: toItem) else { return }
        
        history.moveItem(at: from, to: to)
        
        if to == 0 {
            fromItem.pastesRichText = settings().pastesRichText
            let changeCount = fromItem.write(to: pasteboard)
            HistoryPanel.markSelfWrite(changeCount)
            history.noteClipboardItemId(fromItem.fsId)
            history.recordPasteboardChange(withCount: changeCount)
        }
    }
    
    func toggleFavorite(item: HistoryItem) -> Bool {
        history.toggleFavorite(for: item)
    }
    
    func saveToPasswords(item: HistoryItem, comment: String, login: String, url: String) {
        history.setPassword(true, for: item, comment: comment, login: login, url: url)
    }
    
    func removeFromPasswords(item: HistoryItem) {
        history.setPassword(false, for: item)
    }
    
    func editPasswordEntry(item: HistoryItem, comment: String, login: String, url: String) {
        history.setPasswordMetadata(comment: comment, login: login, url: url, for: item)
    }
    
    func copyLogin(item: HistoryItem) {
        guard !item.passwordLogin.isEmpty else { return }
        copyStringToClipboard(item.passwordLogin, concealed: false)
    }
    
    func copyPasswordURL(item: HistoryItem) {
        guard !item.passwordURL.isEmpty else { return }
        copyStringToClipboard(item.passwordURL, concealed: false)
    }
    
    func openPasswordURL(item: HistoryItem) {
        guard let url = item.passwordOpenableURL else { return }
        NSWorkspace.shared.open(url)
    }
    
    func copyPassword(item: HistoryItem) {
        guard let password = item.getPasswordValue(), !password.isEmpty else { return }
        PasswordAccessGate.shared.authorize { [weak self] ok in
            guard ok, let self else { return }
            let changeCount = self.copyStringToClipboard(password, concealed: true)
            PasswordClipboardClearer.shared.scheduleClear(afterWritingChangeCount: changeCount, pasteboard: self.pasteboard)
        }
    }
    
    @discardableResult
    private func copyStringToClipboard(_ string: String, concealed: Bool) -> Int {
        let changeCount = PasteboardWriter.writeString(string, to: pasteboard, concealed: concealed)
        HistoryPanel.markSelfWrite(changeCount)
        history.clearCurrentClipboardItemId()
        history.recordPasteboardChange(withCount: changeCount)
        return changeCount
    }
}

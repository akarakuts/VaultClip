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
    
    init(history: History, items: [HistoryItem]) {
        self.history = history
        self.items = items
        self.pasteboard = NSPasteboard.general
    }
    
    func paste(item: HistoryItem) {
        guard let index = history.index(of: item) else { return }
        if item.isPassword {
            let alert = NSAlert()
            alert.messageText = "Paste saved password?"
            alert.informativeText = "The password will be placed on the system clipboard where other applications can read it."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Paste")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        history.moveItem(at: index, to: 0)
        
        let newChangeCount = pasteboard.clearContents()
        history.recordPasteboardChange(withCount: newChangeCount)
        item.write(to: pasteboard)
        history.recordPasteboardChange(withCount: pasteboard.changeCount)
        scheduleSimulatedPaste()
    }
    
    func paste(displayedIndex: Int) {
        guard displayedIndex >= 0, displayedIndex < items.count else { return }
        paste(item: items[displayedIndex])
    }
    
    /// Simulates ⌘V in the previously focused app after the history panel closes.
    private func scheduleSimulatedPaste() {
        DispatchQueue.main.async {
            self.performSimulatedPaste(startedAt: Date())
        }
    }

    private func performSimulatedPaste(startedAt: Date) {
        let elapsed = Date().timeIntervalSince(startedAt)

        if State.main.isHistoryPanelShown.value {
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

        guard Helper.isControlGranted(showPopup: true) else { return }
        Helper.pressCommandV()
    }
    
    /// Returns the next row index to select in the displayed list.
    func delete(item: HistoryItem) -> Int? {
        guard let displayedIndex = items.firstIndex(where: { $0.fsId == item.fsId }) else { return nil }
        history.deleteItem(withId: item.fsId)
        
        if displayedIndex == 0 {
            let newChangeCount = pasteboard.clearContents()
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
            let newChangeCount = pasteboard.clearContents()
            history.recordPasteboardChange(withCount: newChangeCount)
            fromItem.write(to: pasteboard)
            history.recordPasteboardChange(withCount: pasteboard.changeCount)
        }
    }
    
    func toggleFavorite(item: HistoryItem) -> Bool {
        history.toggleFavorite(for: item)
    }
    
    func saveToPasswords(item: HistoryItem, comment: String) {
        history.setPassword(true, for: item, comment: comment)
    }
    
    func removeFromPasswords(item: HistoryItem) {
        history.setPassword(false, for: item)
    }
    
    func editPasswordComment(item: HistoryItem, comment: String) {
        history.setPasswordComment(comment, for: item)
    }
}

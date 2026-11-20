//
// HistoryTableView+ContextMenu — double-click paste and registry-built row menu (U11/U17).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

extension HistoryTableView {
    @objc func rowDoubleClicked(_ sender: Any?) {
        guard let index = itemIndex(forRow: clickedRow) else { return }
        historyDelegate?.historyTableView(self, pasteRowAt: index)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let tableRow = self.row(at: point)
        guard let index = itemIndex(forRow: tableRow) else { return nil }
        // Finder rule: right-click outside the selection selects that row first.
        if !selectedRowIndexes.contains(tableRow) {
            selectRowIndexes(IndexSet(integer: tableRow), byExtendingSelection: false)
        }
        return buildContextMenu(for: index)
    }

    func buildContextMenu(for row: Int) -> NSMenu {
        let item = historyListItems[row]
        let kind = HistoryItemSummaryBuilder.shared.kind(for: item)
        let appName = item.sourceBundleId.map { SourceAppDisplayName.name(forBundleId: $0) }
        let model = ContextMenuBuilder.build(
            kind: kind,
            isPassword: item.isPassword,
            isFavorite: item.isFavorite,
            selectionCount: max(1, selectedItemIndexes.count),
            sourceAppName: appName
        )
        let menu = NSMenu(title: "Item")
        menu.autoenablesItems = false
        for (index, block) in model.sections.enumerated() {
            if index > 0 { menu.addItem(.separator()) }
            for entry in block.items {
                let menuItem = NSMenuItem(
                    title: title(for: entry, appName: appName),
                    action: #selector(contextMenuItemChosen(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.isEnabled = entry.isEnabled
                menuItem.representedObject = ContextMenuPayload(row: row, entry: entry)
                menuItem.image = NSImage(systemSymbolName: entry.symbolName, accessibilityDescription: nil)
                if let id = entry.commandID,
                   let chord = PanelCommandRegistry.command(id: id).bindings.first?.chord {
                    menuItem.toolTip = chord.displayString
                }
                menu.addItem(menuItem)
            }
        }
        return menu
    }

    private func title(for entry: ContextMenuItem, appName: String?) -> String {
        switch entry.titleKey {
        case "unfavorite": return L10n.contextRemoveFromFavorites
        case "copyLogin": return L10n.contextCopyLogin
        case "copyPassword": return L10n.contextCopyPassword
        case "copyURL": return L10n.contextCopyURL
        case "openURL": return L10n.contextOpenURL
        case "editPassword": return L10n.contextEdit
        case "removeFromPasswords": return L10n.contextRemoveFromPasswords
        case "saveToPasswords": return L10n.contextSaveToPasswords
        case "filterByApp":
            return "\(L10n.commandTitle(for: "command.filterApp")) «\(appName ?? "")»"
        default:
            if let id = entry.commandID {
                return PanelCommandRegistry.command(id: id).title
            }
            return L10n.commandTitle(for: entry.titleKey)
        }
    }

    @objc private func contextMenuItemChosen(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? ContextMenuPayload,
              payload.row < historyListItems.count,
              let delegate = historyDelegate else { return }
        let row = payload.row
        switch payload.entry.titleKey {
        case "copyLogin": delegate.historyTableView(self, copyPasswordLoginAt: row)
        case "copyPassword": delegate.historyTableView(self, copyPasswordValueAt: row)
        case "copyURL": delegate.historyTableView(self, copyPasswordURLAt: row)
        case "openURL": delegate.historyTableView(self, openPasswordURLAt: row)
        case "editPassword": delegate.historyTableView(self, editPasswordEntryAt: row)
        case "removeFromPasswords": delegate.historyTableView(self, removeFromPasswordsAt: row)
        case "saveToPasswords": delegate.historyTableView(self, saveToPasswordsAt: row)
        case "filterByApp": delegate.historyTableView(self, filterByAppAt: row)
        default:
            if let id = payload.entry.commandID {
                delegate.historyTableView(self, performCommand: id, at: row)
            }
        }
    }
}

private final class ContextMenuPayload: NSObject {
    let row: Int
    let entry: ContextMenuItem

    init(row: Int, entry: ContextMenuItem) {
        self.row = row
        self.entry = entry
    }
}

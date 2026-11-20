//
// ContextMenuModel — NSMenu sections from PanelCommandRegistry (U17).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum ContextMenuSection: String, Equatable {
    case paste
    case item
    case password
    case filter
    case delete
}

struct ContextMenuItem: Equatable {
    var commandID: PanelCommandID?
    var titleKey: String
    var symbolName: String
    var isEnabled: Bool
    var isSeparator: Bool = false
}

struct ContextMenuSectionBlock: Equatable {
    var section: ContextMenuSection
    var items: [ContextMenuItem]
}

struct ContextMenuModel: Equatable {
    var sections: [ContextMenuSectionBlock]
}

enum ContextMenuBuilder {
    static func build(
        kind: ItemKind,
        isPassword: Bool,
        isFavorite: Bool,
        selectionCount: Int,
        sourceAppName: String?
    ) -> ContextMenuModel {
        let multi = selectionCount > 1
        var pasteItems: [ContextMenuItem] = [
            item(.paste, enabled: selectionCount > 0),
            item(.pastePlainText, enabled: selectionCount > 0 && (kind == .richText || kind == .text)),
            item(.copy, enabled: selectionCount > 0)
        ]
        var itemSection: [ContextMenuItem] = [
            item(.toggleFavorite, enabled: !isPassword && selectionCount > 0,
                 titleOverride: isFavorite && !multi ? "unfavorite" : nil),
            item(.editBeforePaste, enabled: !multi && (kind == .text || kind == .richText || kind == .link)),
            item(.togglePreview, enabled: !multi && selectionCount == 1),
            item(.quickLook, enabled: !multi && selectionCount == 1),
            item(.openLinkOrFile, enabled: !multi && (kind == .link || isFileKind(kind) || kind == .pdf)),
            item(.revealInFinder, enabled: !multi && (isFileKind(kind) || kind == .pdf || kind == .image))
        ]

        var passwordSection: [ContextMenuItem] = []
        if isPassword || kind == .password {
            passwordSection = [
                ContextMenuItem(commandID: nil, titleKey: "copyLogin", symbolName: "person", isEnabled: !multi),
                ContextMenuItem(commandID: .copy, titleKey: "copyPassword", symbolName: "key", isEnabled: !multi),
                ContextMenuItem(commandID: nil, titleKey: "copyURL", symbolName: "link", isEnabled: !multi),
                ContextMenuItem(commandID: .openLinkOrFile, titleKey: "openURL", symbolName: "safari", isEnabled: !multi),
                ContextMenuItem(commandID: .editBeforePaste, titleKey: "editPassword", symbolName: "pencil", isEnabled: !multi),
                ContextMenuItem(commandID: nil, titleKey: "removeFromPasswords", symbolName: "lock.open", isEnabled: !multi)
            ]
        } else if !multi {
            passwordSection = [
                ContextMenuItem(commandID: nil, titleKey: "saveToPasswords", symbolName: "lock", isEnabled: true)
            ]
        }

        var filterSection: [ContextMenuItem] = []
        if let name = sourceAppName, !name.isEmpty, !multi {
            filterSection = [
                ContextMenuItem(
                    commandID: .filterApp,
                    titleKey: "filterByApp",
                    symbolName: "app.badge",
                    isEnabled: true
                )
            ]
            _ = name
        }

        let deleteSection: [ContextMenuItem] = [
            item(.delete, enabled: selectionCount > 0)
        ]

        var sections: [ContextMenuSectionBlock] = [
            ContextMenuSectionBlock(section: .paste, items: pasteItems),
            ContextMenuSectionBlock(
                section: .item,
                items: itemSection.filter { $0.isEnabled || $0.commandID == .toggleFavorite }
            )
        ]
        if !passwordSection.isEmpty {
            sections.append(ContextMenuSectionBlock(section: .password, items: passwordSection))
        }
        if !filterSection.isEmpty {
            sections.append(ContextMenuSectionBlock(section: .filter, items: filterSection))
        }
        sections.append(ContextMenuSectionBlock(section: .delete, items: deleteSection))
        return ContextMenuModel(sections: sections)
    }

    private static func item(
        _ id: PanelCommandID,
        enabled: Bool,
        titleOverride: String? = nil
    ) -> ContextMenuItem {
        let command = PanelCommandRegistry.command(id: id)
        return ContextMenuItem(
            commandID: id,
            titleKey: titleOverride ?? command.titleKey,
            symbolName: command.symbolName,
            isEnabled: enabled
        )
    }

    private static func isFileKind(_ kind: ItemKind) -> Bool {
        if case .file = kind { return true }
        return false
    }
}

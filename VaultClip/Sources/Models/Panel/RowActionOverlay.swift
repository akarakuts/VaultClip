//
// RowActionOverlay — hover/selection action buttons per row kind (U15).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum RowActionButtonID: String, Equatable, CaseIterable {
    case paste
    case pastePlainText
    case toggleFavorite
    case more
    case copyLogin
    case copyPassword
}

struct RowActionButton: Equatable {
    var id: RowActionButtonID
    var commandID: PanelCommandID?
    var symbolName: String
    var tooltipKey: String
}

enum RowActionOverlay {
    static func buttons(
        kind: ItemKind,
        isFavorite: Bool,
        tab: HistoryListMode
    ) -> [RowActionButton] {
        if kind == .password || tab == .passwords {
            return [
                RowActionButton(
                    id: .copyLogin,
                    commandID: nil,
                    symbolName: "person",
                    tooltipKey: "copyLogin"
                ),
                RowActionButton(
                    id: .copyPassword,
                    commandID: .copy,
                    symbolName: "key",
                    tooltipKey: "copyPassword"
                ),
                RowActionButton(
                    id: .more,
                    commandID: .commandPalette,
                    symbolName: "ellipsis",
                    tooltipKey: "more"
                )
            ]
        }
        var list: [RowActionButton] = [
            RowActionButton(
                id: .paste,
                commandID: .paste,
                symbolName: "arrow.turn.down.left",
                tooltipKey: "paste"
            )
        ]
        if kind == .richText || kind == .text {
            // «Как текст» only when rich text is available.
            if kind == .richText {
                list.append(RowActionButton(
                    id: .pastePlainText,
                    commandID: .pastePlainText,
                    symbolName: "textformat",
                    tooltipKey: "pastePlainText"
                ))
            }
        }
        list.append(RowActionButton(
            id: .toggleFavorite,
            commandID: .toggleFavorite,
            symbolName: isFavorite ? "star.fill" : "star",
            tooltipKey: "toggleFavorite"
        ))
        list.append(RowActionButton(
            id: .more,
            commandID: .commandPalette,
            symbolName: "ellipsis",
            tooltipKey: "more"
        ))
        return list
    }

    static func tooltip(for button: RowActionButton) -> String {
        if let commandID = button.commandID {
            let command = PanelCommandRegistry.command(id: commandID)
            if let chord = command.bindings.first?.chord {
                return "\(command.title) (\(chord.displayString))"
            }
            return command.title
        }
        switch button.id {
        case .copyLogin: return L10n.contextCopyLogin
        case .copyPassword: return L10n.contextCopyPassword
        case .more: return L10n.command_commandPalette
        default: return button.tooltipKey
        }
    }
}

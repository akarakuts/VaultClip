//
// PanelCommand — registry of panel actions, chords, zones, and availability (U03).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PanelCommandID: String, CaseIterable, Hashable {
    case togglePanel
    case paste
    case pastePlainText
    case quickPaste1, quickPaste2, quickPaste3, quickPaste4, quickPaste5
    case quickPaste6, quickPaste7, quickPaste8, quickPaste9, quickPaste0
    case copy
    case commandPalette
    case focusSearch
    case togglePreview
    case quickLook
    case editBeforePaste
    case pasteEdit
    case saveEdit
    case toggleFavorite
    case delete
    case undoDelete
    case openLinkOrFile
    case revealInFinder
    case selectNext
    case selectPrevious
    case selectFirst
    case selectLast
    case pageUp
    case pageDown
    case extendSelectionUp
    case extendSelectionDown
    case selectAll
    case nextTab
    case previousTab
    case filterTypeAll
    case filterTypeText
    case filterTypeLinks
    case filterTypeImages
    case filterTypeFiles
    case filterTypeColors
    case filterApp
    case clearFilters
    case textSizeIncrease
    case textSizeDecrease
    case cheatSheet
    case openSettings
    case panelPositionLeft
    case panelPositionRight
    case panelPositionUp
    case panelPositionDown
    case closePanel
}

enum PanelCommandGroup: String, Hashable {
    case item
    case view
    case filter
    case app
    case window
}

enum PanelCommandAvailability: Equatable {
    case enabled
    case disabled(reason: String)
    case hidden
}

struct PanelCommandContext: Equatable {
    var hasSelection: Bool = false
    var selectionCount: Int = 0
    var searchIsEmpty: Bool = true
    var searchHasMarkedText: Bool = false
    var canUndoDelete: Bool = false
    var isPasswordTab: Bool = false
    var previewVisible: Bool = true
}

struct PanelCommandChordBinding: Hashable {
    var chord: KeyChord
    var zones: Set<FocusZone>
}

struct PanelCommand {
    let id: PanelCommandID
    let titleKey: String
    let keywords: [String]
    let symbolName: String
    let bindings: [PanelCommandChordBinding]
    let group: PanelCommandGroup
    let isDestructive: Bool
    /// When false, command is menu-bar / settings only — not listed in ⌘K palette.
    let showsInPalette: Bool
    let availability: (PanelCommandContext) -> PanelCommandAvailability

    var title: String { L10n.commandTitle(for: titleKey) }

    var chords: [KeyChord] { bindings.map(\.chord) }
    var zones: Set<FocusZone> { Set(bindings.flatMap(\.zones)) }
}

enum PanelCommandRegistry {
    static let all: [PanelCommand] = makeAll()

    static func command(id: PanelCommandID) -> PanelCommand {
        guard let found = all.first(where: { $0.id == id }) else {
            preconditionFailure("missing command \(id)")
        }
        return found
    }

    static func commands(matching chord: KeyChord, in zone: FocusZone) -> [PanelCommand] {
        all.filter { cmd in
            cmd.bindings.contains { $0.chord == chord && $0.zones.contains(zone) }
        }
    }

    static func resolve(chord: KeyChord, in zone: FocusZone) -> PanelCommandID? {
        let hits = commands(matching: chord, in: zone)
        return hits.count == 1 ? hits[0].id : nil
    }

    private static let navigationZones: Set<FocusZone> = [.search, .list]
    private static let itemZones: Set<FocusZone> = [.search, .list, .preview]
    private static let panelZones: Set<FocusZone> = [.search, .list, .preview, .filters]
    private static let everywhere: Set<FocusZone> = Set(FocusZone.allCases)

    // swiftlint:disable:next function_body_length
    private static func makeAll() -> [PanelCommand] {
        let alwaysEnabled: (PanelCommandContext) -> PanelCommandAvailability = { _ in .enabled }
        let needsSelection: (PanelCommandContext) -> PanelCommandAvailability = {
            $0.hasSelection ? .enabled : .disabled(reason: "no selection")
        }

        func bind(_ chord: KeyChord, _ zones: Set<FocusZone>) -> PanelCommandChordBinding {
            PanelCommandChordBinding(chord: chord, zones: zones)
        }

        func cmd(
            _ id: PanelCommandID,
            keywords: [String],
            symbol: String,
            bindings: [PanelCommandChordBinding],
            group: PanelCommandGroup,
            destructive: Bool = false,
            palette: Bool = true,
            availability: @escaping (PanelCommandContext) -> PanelCommandAvailability = alwaysEnabled
        ) -> PanelCommand {
            PanelCommand(
                id: id,
                titleKey: "command.\(id.rawValue)",
                keywords: keywords,
                symbolName: symbol,
                bindings: bindings,
                group: group,
                isDestructive: destructive,
                showsInPalette: palette,
                availability: availability
            )
        }

        var list: [PanelCommand] = [
            cmd(.togglePanel, keywords: ["toggle", "panel", "панель"], symbol: "clipboard",
                bindings: [], group: .window, palette: false),
            cmd(.paste, keywords: ["paste", "вставить"], symbol: "return",
                bindings: [bind(KeyChord(key: .return, modifiers: []), itemZones)], group: .item,
                availability: needsSelection),
            cmd(.pastePlainText, keywords: ["plain", "простой", "text"], symbol: "textformat",
                bindings: [bind(KeyChord(key: .return, modifiers: .shift), itemZones)], group: .item,
                availability: needsSelection),
            cmd(.copy, keywords: ["copy", "копировать"], symbol: "doc.on.doc",
                bindings: [bind(.cmd("c"), [.list, .search, .preview])], group: .item,
                availability: needsSelection),
            cmd(.commandPalette, keywords: ["palette", "actions", "палитра", "действия"], symbol: "command",
                bindings: [bind(.cmd("k"), everywhere)], group: .view),
            cmd(.focusSearch, keywords: ["search", "поиск", "find"], symbol: "magnifyingglass",
                bindings: [bind(.cmd("f"), everywhere)], group: .view),
            cmd(.togglePreview, keywords: ["preview", "превью"], symbol: "sidebar.right",
                bindings: [
                    bind(.cmd("y"), panelZones),
                    bind(KeyChord(key: .space, modifiers: []), [.list])
                ], group: .view),
            cmd(.quickLook, keywords: ["quick look", "просмотр"], symbol: "eye",
                bindings: [bind(KeyChord(key: .space, modifiers: .option), [.list])], group: .view,
                availability: needsSelection),
            cmd(.editBeforePaste, keywords: ["edit", "править"], symbol: "pencil",
                bindings: [bind(.cmd("e"), [.list, .preview])], group: .item, availability: needsSelection),
            cmd(.pasteEdit, keywords: ["paste edit", "вставить правку"], symbol: "return",
                bindings: [bind(KeyChord(key: .return, modifiers: .command), [.editor])], group: .item),
            cmd(.saveEdit, keywords: ["save", "сохранить"], symbol: "square.and.arrow.down",
                bindings: [bind(.cmd("s"), [.editor])], group: .item),
            cmd(.toggleFavorite, keywords: ["favorite", "избранное", "star"], symbol: "star",
                bindings: [bind(.cmd("d"), itemZones)], group: .item, availability: needsSelection),
            cmd(.delete, keywords: ["delete", "удалить"], symbol: "trash",
                bindings: [
                    bind(KeyChord(key: .delete, modifiers: .command), [.list, .preview, .search]),
                    bind(KeyChord(key: .delete, modifiers: []), [.list]),
                    bind(KeyChord(key: .delete, modifiers: .control), [.list, .preview])
                ], group: .item, destructive: true, availability: needsSelection),
            cmd(.undoDelete, keywords: ["undo", "отменить"], symbol: "arrow.uturn.backward",
                bindings: [bind(.cmd("z"), [.list, .preview, .filters])], group: .item,
                availability: { $0.canUndoDelete ? .enabled : .disabled(reason: "nothing to undo") }),
            cmd(.openLinkOrFile, keywords: ["open", "открыть"], symbol: "arrow.up.right.square",
                bindings: [bind(.cmd("o"), [.list, .preview])], group: .item, availability: needsSelection),
            cmd(.revealInFinder, keywords: ["finder", "показать"], symbol: "folder",
                bindings: [bind(.cmd("r"), [.list, .preview])], group: .item, availability: needsSelection),
            cmd(.selectNext, keywords: ["next", "вниз"], symbol: "arrow.down",
                bindings: [bind(KeyChord(key: .downArrow, modifiers: []), navigationZones)], group: .view),
            cmd(.selectPrevious, keywords: ["previous", "вверх"], symbol: "arrow.up",
                bindings: [bind(KeyChord(key: .upArrow, modifiers: []), navigationZones)], group: .view),
            cmd(.selectFirst, keywords: ["first", "начало"], symbol: "arrow.up.to.line",
                bindings: [
                    bind(KeyChord(key: .upArrow, modifiers: .command), navigationZones),
                    bind(KeyChord(key: .home, modifiers: []), navigationZones)
                ], group: .view),
            cmd(.selectLast, keywords: ["last", "конец"], symbol: "arrow.down.to.line",
                bindings: [
                    bind(KeyChord(key: .downArrow, modifiers: .command), navigationZones),
                    bind(KeyChord(key: .end, modifiers: []), navigationZones)
                ], group: .view),
            cmd(.pageUp, keywords: ["page up"], symbol: "arrow.up.doc",
                bindings: [bind(KeyChord(key: .pageUp, modifiers: []), navigationZones)], group: .view),
            cmd(.pageDown, keywords: ["page down"], symbol: "arrow.down.doc",
                bindings: [bind(KeyChord(key: .pageDown, modifiers: []), navigationZones)], group: .view),
            cmd(.extendSelectionUp, keywords: ["extend", "выделение"], symbol: "arrow.up",
                bindings: [bind(KeyChord(key: .upArrow, modifiers: .shift), navigationZones)], group: .item),
            cmd(.extendSelectionDown, keywords: ["extend", "выделение"], symbol: "arrow.down",
                bindings: [bind(KeyChord(key: .downArrow, modifiers: .shift), navigationZones)], group: .item),
            cmd(.selectAll, keywords: ["select all", "выделить всё"], symbol: "checklist",
                bindings: [bind(.cmd("a"), [.list])], group: .item),
            cmd(.nextTab, keywords: ["next tab", "вкладка"], symbol: "forward",
                bindings: [
                    bind(KeyChord(key: .tab, modifiers: .control), panelZones),
                    bind(KeyChord(key: .rightBracket, modifiers: [.command, .shift]), panelZones),
                    bind(KeyChord(key: .rightBracket, modifiers: .control), panelZones)
                ], group: .view),
            cmd(.previousTab, keywords: ["previous tab", "вкладка"], symbol: "backward",
                bindings: [
                    bind(KeyChord(key: .tab, modifiers: [.control, .shift]), panelZones),
                    bind(KeyChord(key: .leftBracket, modifiers: [.command, .shift]), panelZones),
                    bind(KeyChord(key: .leftBracket, modifiers: .control), panelZones)
                ], group: .view),
            cmd(.filterTypeAll, keywords: ["filter", "все"], symbol: "line.3.horizontal.decrease.circle",
                bindings: [bind(.optionCmdDigit(1), panelZones)], group: .filter),
            cmd(.filterTypeText, keywords: ["filter", "text", "текст"], symbol: "text.alignleft",
                bindings: [bind(.optionCmdDigit(2), panelZones)], group: .filter),
            cmd(.filterTypeLinks, keywords: ["filter", "link", "ссылки"], symbol: "link",
                bindings: [bind(.optionCmdDigit(3), panelZones)], group: .filter),
            cmd(.filterTypeImages, keywords: ["filter", "image", "изображения"], symbol: "photo",
                bindings: [bind(.optionCmdDigit(4), panelZones)], group: .filter),
            cmd(.filterTypeFiles, keywords: ["filter", "file", "файлы"], symbol: "doc",
                bindings: [bind(.optionCmdDigit(5), panelZones)], group: .filter),
            cmd(.filterTypeColors, keywords: ["filter", "color", "цвета"], symbol: "paintpalette",
                bindings: [bind(.optionCmdDigit(6), panelZones)], group: .filter),
            cmd(.filterApp, keywords: ["app", "приложение"], symbol: "app.badge",
                bindings: [bind(KeyChord(key: .letter("a"), modifiers: [.option, .command]), panelZones)],
                group: .filter),
            cmd(.clearFilters, keywords: ["clear filters", "сбросить"], symbol: "xmark.circle",
                bindings: [bind(.optionCmdDigit(0), panelZones)], group: .filter),
            cmd(.textSizeIncrease, keywords: ["larger", "крупнее"], symbol: "textformat.size.larger",
                bindings: [bind(KeyChord(key: .equal, modifiers: .command), everywhere)], group: .view),
            cmd(.textSizeDecrease, keywords: ["smaller", "мельче"], symbol: "textformat.size.smaller",
                bindings: [bind(KeyChord(key: .minus, modifiers: .command), everywhere)], group: .view),
            cmd(.cheatSheet, keywords: ["shortcuts", "шпаргалка", "keys"], symbol: "keyboard",
                bindings: [bind(KeyChord(key: .slash, modifiers: .command), everywhere)], group: .view),
            cmd(.openSettings, keywords: ["settings", "preferences", "настройки"], symbol: "gearshape",
                bindings: [bind(KeyChord(key: .comma, modifiers: .command), everywhere)], group: .app),
            cmd(.panelPositionLeft, keywords: ["left", "слева"], symbol: "rectangle.lefthalf.inset.filled",
                bindings: [bind(KeyChord(key: .leftArrow, modifiers: [.control, .option, .command]), panelZones)],
                group: .window),
            cmd(.panelPositionRight, keywords: ["right", "справа"], symbol: "rectangle.righthalf.inset.filled",
                bindings: [bind(KeyChord(key: .rightArrow, modifiers: [.control, .option, .command]), panelZones)],
                group: .window),
            cmd(.panelPositionUp, keywords: ["top", "сверху"], symbol: "rectangle.tophalf.inset.filled",
                bindings: [bind(KeyChord(key: .upArrow, modifiers: [.control, .option, .command]), panelZones)],
                group: .window),
            cmd(.panelPositionDown, keywords: ["bottom", "снизу"], symbol: "rectangle.bottomhalf.inset.filled",
                bindings: [bind(KeyChord(key: .downArrow, modifiers: [.control, .option, .command]), panelZones)],
                group: .window),
            cmd(.closePanel, keywords: ["close", "закрыть"], symbol: "xmark",
                bindings: [
                    bind(KeyChord(key: .escape, modifiers: []), everywhere),
                    bind(KeyChord(key: .letter("w"), modifiers: .command), everywhere)
                ], group: .window)
        ]

        let quickPaste: [(PanelCommandID, Int)] = [
            (.quickPaste1, 1), (.quickPaste2, 2), (.quickPaste3, 3), (.quickPaste4, 4), (.quickPaste5, 5),
            (.quickPaste6, 6), (.quickPaste7, 7), (.quickPaste8, 8), (.quickPaste9, 9), (.quickPaste0, 0)
        ]
        for (id, n) in quickPaste {
            list.append(cmd(
                id,
                keywords: ["quick paste", "быстрая", "\(n)"],
                symbol: "\(n).circle",
                bindings: [bind(.cmdDigit(n), panelZones)],
                group: .item
            ))
        }

        return list
    }
}

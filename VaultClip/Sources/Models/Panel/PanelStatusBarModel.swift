//
// PanelStatusBarModel — footer counter, hints, banners, toast policy (U09).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import CoreGraphics
import Foundation

enum PanelHintContext: Equatable {
    case list
    case multiSelect(count: Int)
    case editor
}

struct PanelStatusBarInput: Equatable {
    var totalCount: Int
    var visibleCount: Int
    var isSearch: Bool
    var selectedCount: Int
    var isLoading: Bool
    var hintContext: PanelHintContext
    var availableWidth: CGFloat
    var showKeyHints: Bool
    var locale: Locale
}

struct PanelStatusBarModel: Equatable {
    var counterText: String
    var hints: [String]
}

enum PanelStatusBarPresenter {
    static let footerHeight: CGFloat = 24
    static let toastNormalSeconds: TimeInterval = 4
    static let toastUndoSeconds: TimeInterval = 8

    static func present(_ input: PanelStatusBarInput) -> PanelStatusBarModel {
        PanelStatusBarModel(
            counterText: counter(for: input),
            hints: hints(for: input)
        )
    }

    static func counter(for input: PanelStatusBarInput) -> String {
        let ru = input.locale.language.languageCode?.identifier == "ru"
        if input.isLoading {
            return ru ? "Загрузка…" : "Loading…"
        }
        if input.selectedCount > 1 {
            return ru ? "\(input.selectedCount) выбрано" : "\(input.selectedCount) selected"
        }
        if input.isSearch {
            return ru
                ? "Найдено \(input.visibleCount) из \(input.totalCount)"
                : "Found \(input.visibleCount) of \(input.totalCount)"
        }
        if ru {
            return "\(input.totalCount) \(russianItemsWord(input.totalCount))"
        }
        return input.totalCount == 1 ? "1 item" : "\(input.totalCount) items"
    }

    static func hints(for input: PanelStatusBarInput) -> [String] {
        guard input.showKeyHints else { return [] }
        let ru = input.locale.language.languageCode?.identifier == "ru"
        let all: [String]
        switch input.hintContext {
        case .list:
            all = ru
                ? ["⏎ Вставить", "⌘K Действия", "⌘/ Клавиши"]
                : ["⏎ Paste", "⌘K Actions", "⌘/ Keys"]
        case .multiSelect(let count):
            all = ru
                ? ["⏎ Вставить \(count)", "Esc Снять выделение"]
                : ["⏎ Paste \(count)", "Esc Clear selection"]
        case .editor:
            all = ru
                ? ["⌘⏎ Вставить", "⌘S Сохранить", "Esc Отмена"]
                : ["⌘⏎ Paste", "⌘S Save", "Esc Cancel"]
        }
        // Drop from the end when width is tight (~90pt per hint).
        let maxHints = max(0, Int(input.availableWidth / 90))
        return Array(all.prefix(min(3, maxHints)))
    }

    private static func russianItemsWord(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1, mod100 != 11 { return "элемент" }
        if (2...4).contains(mod10), !(12...14).contains(mod100) { return "элемента" }
        return "элементов"
    }
}

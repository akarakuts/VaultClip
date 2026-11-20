//
// MultiPasteComposer — join selected items for multi-paste (U16).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum MultiPasteSeparator: String, CaseIterable {
    case newline
    case blankLine
    case space
    case comma
    case tab

    var value: String {
        switch self {
        case .newline: return "\n"
        case .blankLine: return "\n\n"
        case .space: return " "
        case .comma: return ", "
        case .tab: return "\t"
        }
    }
}

enum MultiPastePayload: Equatable {
    case joinedText(String)
    case discreteItems(count: Int)
}

struct MultiPasteResult: Equatable {
    var payload: MultiPastePayload?
    var skippedPasswords: Int
    var skippedImages: Int
    var skippedOther: Int
}

enum MultiPasteComposer {
    struct Item: Equatable {
        var kind: ItemKind
        var text: String?
        var isPassword: Bool
    }

    static func compose(
        items: [Item],
        separator: MultiPasteSeparator = .newline,
        reverse: Bool = false
    ) -> MultiPasteResult {
        let ordered = reverse ? Array(items.reversed()) : items
        var skippedPasswords = 0
        var skippedImages = 0
        var skippedOther = 0
        var texts: [String] = []
        var fileLike = 0
        var imageOnly = 0

        for item in ordered {
            if item.isPassword || item.kind == .password {
                skippedPasswords += 1
                continue
            }
            switch item.kind {
            case .image:
                imageOnly += 1
            case .file, .pdf:
                fileLike += 1
            case .text, .richText, .link, .color:
                if let text = item.text, !text.isEmpty {
                    texts.append(text)
                } else {
                    skippedOther += 1
                }
            case .password:
                skippedPasswords += 1
            }
        }

        if !texts.isEmpty, imageOnly == 0, fileLike == 0 {
            return MultiPasteResult(
                payload: .joinedText(texts.joined(separator: separator.value)),
                skippedPasswords: skippedPasswords,
                skippedImages: 0,
                skippedOther: skippedOther
            )
        }
        if texts.isEmpty, imageOnly > 0, fileLike == 0 {
            return MultiPasteResult(
                payload: .discreteItems(count: imageOnly),
                skippedPasswords: skippedPasswords,
                skippedImages: 0,
                skippedOther: skippedOther
            )
        }
        if texts.isEmpty, fileLike > 0, imageOnly == 0 {
            return MultiPasteResult(
                payload: .discreteItems(count: fileLike),
                skippedPasswords: skippedPasswords,
                skippedImages: 0,
                skippedOther: skippedOther
            )
        }
        // Mixed: join text parts, skip the rest.
        return MultiPasteResult(
            payload: texts.isEmpty ? nil : .joinedText(texts.joined(separator: separator.value)),
            skippedPasswords: skippedPasswords,
            skippedImages: imageOnly,
            skippedOther: skippedOther + fileLike
        )
    }
}

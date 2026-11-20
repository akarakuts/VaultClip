//
// DragOutPayload — pasteboard types written when dragging rows out (U19).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import UniformTypeIdentifiers

enum DragOutType: String, Equatable {
    case plainText
    case rtf
    case url
    case fileURL
    case image
    case internalReorder
}

enum DragOutPayload {
    /// Types promised for an external drop. Empty means drag is refused (passwords).
    static func externalTypes(for kind: ItemKind, isPassword: Bool) -> [DragOutType] {
        if isPassword || kind == .password { return [] }
        switch kind {
        case .text:
            return [.plainText]
        case .richText:
            return [.rtf, .plainText]
        case .link:
            return [.url, .plainText]
        case .file(_), .pdf:
            return [.fileURL]
        case .image:
            return [.image, .fileURL]
        case .color:
            return [.plainText]
        case .password:
            return []
        }
    }

    static func allowsInternalReorder(
        selectionCount: Int,
        tab: HistoryListMode,
        isSearching: Bool
    ) -> Bool {
        selectionCount == 1 && !isSearching && (tab == .history || tab == .favorites)
    }

    static func utTypes(for types: [DragOutType]) -> [UTType] {
        types.compactMap { type in
            switch type {
            case .plainText: return .plainText
            case .rtf: return .rtf
            case .url: return .url
            case .fileURL: return .fileURL
            case .image: return .image
            case .internalReorder: return nil
            }
        }
    }
}

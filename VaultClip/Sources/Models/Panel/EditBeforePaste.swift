//
// EditBeforePaste — availability and save/paste rules for edit mode (U24).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum EditBeforePasteAvailability: Equatable {
    case available
    case availableWithRichTextWarning
    case unavailable
}

enum EditBeforePaste {
    static func availability(for kind: ItemKind) -> EditBeforePasteAvailability {
        switch kind {
        case .text, .link:
            return .available
        case .richText:
            return .availableWithRichTextWarning
        case .password, .image, .file, .color, .pdf:
            return .unavailable
        }
    }

    /// Esc stack: dirty editor → confirm discard; clean → leave editor.
    enum EscapeAction: Equatable {
        case confirmDiscard
        case leaveEditor
        case closePanel
    }

    static func escapeAction(isEditing: Bool, isDirty: Bool, canClosePanel: Bool) -> EscapeAction {
        if isEditing {
            return isDirty ? .confirmDiscard : .leaveEditor
        }
        return canClosePanel ? .closePanel : .leaveEditor
    }
}

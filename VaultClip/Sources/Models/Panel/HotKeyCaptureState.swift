//
// HotKeyCaptureState — global hotkey recorder UI states (U31).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum HotKeyCapturePhase: Equatable {
    case idle
    case listening
    case valid
    case invalid(message: String)
}

enum HotKeyCaptureState {
    static func message(for result: HotKeyValidationResult) -> String? {
        switch result {
        case .ok:
            return nil
        case .needsModifier:
            return L10n.hotkeyErrorNeedsModifier
        case .systemShortcut:
            return L10n.hotkeyErrorSystemShortcut
        case .panelConflict:
            return L10n.hotkeyErrorPanelConflict
        case .invalidKey:
            return L10n.hotkeyErrorInvalidKey
        }
    }

    static func phase(after result: HotKeyValidationResult) -> HotKeyCapturePhase {
        if case .ok = result { return .valid }
        if let message = message(for: result) {
            return .invalid(message: message)
        }
        return .idle
    }
}

/// Mirrors HotKeyValidator outcomes without AppKit in call sites that only need messages.
enum HotKeyValidationResult: Equatable {
    case ok
    case needsModifier
    case systemShortcut
    case panelConflict
    case invalidKey
}

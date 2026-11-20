//
// ClipboardSource — resolve copy-origin bundle id vs our own process.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

/// When VaultClip is frontmost, prefer the last tracked non-self app as the clipboard source.
enum ClipboardSource {
    static func resolve(frontmost: String?, tracked: String?) -> String? {
        if frontmost == AppIdentity.bundleIdentifier {
            return tracked
        }
        return frontmost ?? tracked
    }
}

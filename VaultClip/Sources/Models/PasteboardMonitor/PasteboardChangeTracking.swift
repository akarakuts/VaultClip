//
// PasteboardChangeTracking — minimal pasteboard surface for polling monitors.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

protocol PasteboardChangeTracking: AnyObject {
    var changeCount: Int { get }
}

extension NSPasteboard: PasteboardChangeTracking {}

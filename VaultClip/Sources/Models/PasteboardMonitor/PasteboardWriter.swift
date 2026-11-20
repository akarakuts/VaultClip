//
// PasteboardWriter — single write path for clipboard contents (concealed / local-only).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

enum PasteboardWriter {

    static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    static let sourceType = NSPasteboard.PasteboardType("org.nspasteboard.source")

    /// Replaces pasteboard contents with `item`. When `concealed`, marks the payload and keeps it off Universal Clipboard.
    @discardableResult
    static func write(_ item: NSPasteboardItem, to pasteboard: NSPasteboard, concealed: Bool) -> Int {
        let options: NSPasteboard.ContentsOptions = concealed ? .currentHostOnly : []
        _ = pasteboard.prepareForNewContents(with: options)

        if concealed {
            item.setData(Data(), forType: concealedType)
        }
        item.setString(AppIdentity.bundleIdentifier, forType: sourceType)

        pasteboard.writeObjects([item])
        return pasteboard.changeCount
    }

    @discardableResult
    static func writeString(_ string: String, to pasteboard: NSPasteboard, concealed: Bool) -> Int {
        let item = NSPasteboardItem()
        item.setString(string, forType: .string)
        return write(item, to: pasteboard, concealed: concealed)
    }
}

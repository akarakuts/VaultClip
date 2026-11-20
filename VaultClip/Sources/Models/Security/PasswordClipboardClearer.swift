//
// PasswordClipboardClearer — timed clear of concealed password clipboard writes (T30).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Foundation

protocol ClipboardClearScheduling: AnyObject {
    func schedule(after seconds: TimeInterval, execute: @escaping () -> Void)
    func cancel()
}

final class DispatchClipboardClearScheduler: ClipboardClearScheduling {
    private var work: DispatchWorkItem?

    func schedule(after seconds: TimeInterval, execute: @escaping () -> Void) {
        cancel()
        let item = DispatchWorkItem(block: execute)
        work = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    func cancel() {
        work?.cancel()
        work = nil
    }
}

final class PasswordClipboardClearer {
    static let shared = PasswordClipboardClearer()

    var scheduler: ClipboardClearScheduling = DispatchClipboardClearScheduler()
    private var expectedChangeCount: Int?

    func scheduleClear(afterWritingChangeCount changeCount: Int, pasteboard: NSPasteboard = .general) {
        let seconds = Settings.main.passwordClipboardClearSeconds
        guard seconds > 0 else { return }
        expectedChangeCount = changeCount
        scheduler.schedule(after: TimeInterval(seconds)) { [weak self] in
            self?.clearIfUnchanged(pasteboard: pasteboard)
        }
    }

    func clearIfUnchanged(pasteboard: NSPasteboard) {
        guard let expected = expectedChangeCount else { return }
        guard pasteboard.changeCount == expected else { return }
        let newCount = pasteboard.clearContents()
        HistoryPanel.lastSelfWriteChangeCount = newCount
        if let history = AppEnvironment.shared?.state.history {
            history.recordPasteboardChange(withCount: newCount)
            history.clearCurrentClipboardItemId()
        }
        expectedChangeCount = nil
    }
}

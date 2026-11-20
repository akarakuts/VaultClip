//
// KeyCodeResolver — map character “v” to the current keyboard layout keycode for ⌘V.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Carbon
import CoreGraphics

enum KeyCodeResolver {
    /// QWERTY fallback for “v”.
    static let fallbackVKeyCode: CGKeyCode = 9

    private static var cachedVKeyCode: CGKeyCode?
    private static var observer: NSObjectProtocol?

    static func keyCodeForV() -> CGKeyCode {
        if let cached = cachedVKeyCode { return cached }
        let resolved = resolveVKeyCodeFromCurrentLayout() ?? fallbackVKeyCode
        cachedVKeyCode = resolved
        startObservingLayoutChangesIfNeeded()
        return resolved
    }

    /// Pure mapping used by tests: walk keycodes 0…127 via a translate callback.
    static func keyCode(for character: Character, translate: (UInt16) -> String?) -> CGKeyCode? {
        let target = String(character).lowercased()
        for code in UInt16(0)...UInt16(127) {
            guard let produced = translate(code)?.lowercased(), produced == target else { continue }
            return CGKeyCode(code)
        }
        return nil
    }

    static func clearCache() {
        cachedVKeyCode = nil
    }

    private static func resolveVKeyCodeFromCurrentLayout() -> CGKeyCode? {
        guard let data = currentKeyboardLayoutData() else { return nil }
        return keyCode(for: "v") { code in
            translate(keyCode: code, layoutData: data)
        }
    }

    private static func currentKeyboardLayoutData() -> Data? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let cfData = unsafeBitCast(raw, to: CFData.self)
        return cfData as Data
    }

    private static func translate(keyCode: UInt16, layoutData: Data) -> String? {
        layoutData.withUnsafeBytes { rawBuffer -> String? in
            guard let base = rawBuffer.baseAddress else { return nil }
            let layout = base.assumingMemoryBound(to: UCKeyboardLayout.self)
            var deadKeyState: UInt32 = 0
            var chars: [UniChar] = Array(repeating: 0, count: 4)
            var length: Int = 0
            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length)
        }
    }

    private static func startObservingLayoutChangesIfNeeded() {
        guard observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"),
            object: nil,
            queue: .main
        ) { _ in
            clearCache()
        }
    }
}

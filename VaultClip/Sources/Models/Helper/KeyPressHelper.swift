//
//  KeyPressHelper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import ApplicationServices
import CoreGraphics
import Foundation

class KeyPressHelper {

    func press(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard AXIsProcessTrusted() else {
            NSLog("\(Constants.branding.displayName): Accessibility permission is required to simulate key presses")
            return
        }

        guard let sourceRef = CGEventSource(stateID: .hidSystemState) else {
            NSLog("\(Constants.branding.displayName): could not create CGEventSource")
            return
        }

        guard let keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                         virtualKey: keyCode,
                                         keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: sourceRef,
                                       virtualKey: keyCode,
                                       keyDown: false) else {
            NSLog("\(Constants.branding.displayName): could not create keyboard events")
            return
        }

        keyDownEvent.flags = flags
        keyUpEvent.flags = flags

        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
}

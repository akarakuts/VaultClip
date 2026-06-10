//
//  Helper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

class Helper {
    
    // MARK: - Key Press
    
    static var keyPressHelper = KeyPressHelper()
    
    static func press(keyCode: CGKeyCode, flags: CGEventFlags) {
        keyPressHelper.press(keyCode: keyCode, flags: flags)
    }
    
    static func pressCommandV() {
        Helper.press(keyCode: 9, flags: .maskCommand)
    }
    
    // MARK: - Access Control
    
    static var accessControlHelper = AccessControlHelper()
    
    static func isControlGranted() -> Bool {
        return Helper.accessControlHelper.isControlGranted()
    }
    
    static func isControlGranted(showPopup: Bool) -> Bool {
        return Helper.accessControlHelper.isControlGranted(showPopup: showPopup)
    }

    static func openAccessibilitySettings() {
        AccessControlHelper.openAccessibilitySettings()
    }

    static func notifyPasteBlockedIfNeeded() {
        AccessControlHelper.notifyPasteBlockedIfNeeded()
    }
}








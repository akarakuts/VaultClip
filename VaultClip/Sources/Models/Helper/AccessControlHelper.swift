//
//  AccessControlHelper.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import ApplicationServices
import Foundation

class AccessControlHelper {
    
    // https://stackoverflow.com/questions/40144259/modify-accessibility-settings-on-macos-with-swift
    
    func isControlGranted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func isControlGranted(showPopup: Bool) -> Bool {
        // get the value for accesibility
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        // set the options: false means it wont ask
        // true means it will popup and ask
        let options = [checkOptPrompt: showPopup]
        // translate into boolean value
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return accessEnabled
    }
}

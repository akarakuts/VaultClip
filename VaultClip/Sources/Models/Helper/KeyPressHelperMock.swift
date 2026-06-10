//
//  KeyPressHelperMock.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

class KeyPressHelperMock: KeyPressHelper {
    
    override func press(keyCode: CGKeyCode, flags: CGEventFlags) {
        KeyPressMock.keyPress(keyCode: keyCode, flags: flags)
    }
}

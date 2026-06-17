//
//  AccessControlHelperMock.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class AccessControlHelperMock: AccessControlHelper {
    
    override func isControlGranted() -> Bool {
        return AccessControlMock.isControlGranted()
    }
    
    override func isControlGranted(showPopup: Bool) -> Bool {
        return AccessControlMock.isControlGranted()
    }
}

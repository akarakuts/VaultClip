//
//  Alerter.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class Alerter {
    
    static var general = Alerter()
    
    func show(_ alertable: Alertable) {
        // XCTest host: never block on runModal (same rule as HistoryFileManager quarantine alerts).
        guard !AppIdentity.isRunningUnitTests else { return }
        DispatchQueue.main.async {
            // Suspend panel auto-close so resign-active from the alert does not hide history (T06).
            PanelFocusGuard.withSuspended {
                alertable.createAlert().runModal()
            }
        }
    }
}

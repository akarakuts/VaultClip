//
//  HistoryWindowController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import RxSwift
import RxRelay

class HistoryWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 2)
        window?.setAccessibilityIdentifier(Accessibility.identifiers.historyWindow)
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    static func createHistoryWindowController() -> HistoryWindowController {
        return NSStoryboard.instantiateOrTerminate(identifier: "HistoryWindowController")
    }
    
    private var oldApp: NSRunningApplication?
    
    func subscribeTo(toggle: BehaviorRelay<Bool>) -> Disposable {
        return toggle
            .subscribe(onNext: {
                [] in
                if !$0 {
                    self.close()
                    self.oldApp?.activate(options: .activateIgnoringOtherApps)
                }
                else {
                    self.oldApp = NSWorkspace.shared.frontmostApplication
                    self.showWindow(nil)
                    self.window?.makeKey()
                    NSApp.activate(ignoringOtherApps: true)
                }
            })
    }
    
    func subscribeFrameTo(position: Observable<PanelPosition>, screen: Observable<NSScreen>) -> Disposable {
        Observable.combineLatest(position, screen).subscribe(onNext: {
            (position, screen) in
            self.window?.setFrame(position.getFrame(forScreen: screen), display: true)
        })
    }
}

//
//  AppDelegate.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let disposeBag = DisposeBag()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkBuildFlags()
        checkLaunchArgs()
        AppDataMigrator.migrateIfNeeded()
        Controller.main = Controller(state: State.main, settings: Settings.main)
        LaunchAtLoginHelper.reconcile(wantsLaunchAtLogin: Controller.main.state.launchAtLogin.value)
        LaunchAtLoginHelper.warnIfRunningFromTransientLocation()

        showWelcomeIfNeeded()

        setupHotKey()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    func checkLaunchArgs() {
        if CommandLine.arguments.contains("--uitesting") {
            do {
                try UITesting.setupUITestEnvironment(launchArgs: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
            }
            catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    func checkBuildFlags() {
        #if BETA
        ClipStatusItem.statusItemButtonImage = NSImage(named: NSImage.Name("BetaStatusBarIcon"))
        #endif
    }
    
    func showWelcomeIfNeeded() {
        // If the user has enabled access we don't need to do anything
        if Helper.isControlGranted(showPopup: false) {
            return
        }
        
        // Otherwise we should show a popup detailing why access is required.
        Controller.main.welcomeWindowController.showWindow(nil)
        
        // Bring the window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupHotKey() {
        ClipHotKeys.toggle.changeHotKey(keyCombo: Settings.main.toggleHotKey)
        ClipHotKeys.toggle.onDown {
            Controller.main.togglePopover()
        }
    }
}

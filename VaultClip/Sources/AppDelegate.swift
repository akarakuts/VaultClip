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
        EncryptionKeyBootstrap.prepareAtLaunch()
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
        // One onboarding surface per launch; system prompt only after the user taps Allow Access.
        AccessControlHelper.presentWelcomeIfNeeded()
    }
    
    func setupHotKey() {
        ClipHotKeys.toggle.changeHotKey(keyCombo: Settings.main.toggleHotKey)
        ClipHotKeys.toggle.onDown {
            Controller.main.togglePopover()
        }
    }
}

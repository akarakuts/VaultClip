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

    #if DEBUG
    private var unitTestStorageRoot: URL?
    #endif

    func applicationWillFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if AppIdentity.isRunningUnitTests {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "VaultClip-UnitTests-\(ProcessInfo.processInfo.processIdentifier)",
                    isDirectory: true
                )
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            StorageRoot.override = root
            unitTestStorageRoot = root
            AppIdentity.assertStorageIsIsolatedIfNeeded()
        }
        #endif
        _ = SingleInstanceGuard.terminateIfDuplicate()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard !SingleInstanceGuard.isDuplicateTermination else { return }

        checkBuildFlags()
        checkLaunchArgs()
        LogStorage.secureAtLaunch()
        QuickLookTempStore.shared.removeAll()
        AppDataMigrator.migrateIfNeeded()
        EncryptionKeyBootstrap.prepareAtLaunch()
        let environment = AppEnvironment.bootstrap()
        let controller = Controller(state: environment.state, settings: environment.settings)
        environment.attachController(controller)

        if !AppIdentity.isRunningUnitTests {
            LaunchAtLoginHelper.warnIfRunningFromTransientLocation()
            showWelcomeIfNeeded()
            setupHotKey()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(refreshLaunchAtLoginOnActivate),
                name: NSApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    @objc private func refreshLaunchAtLoginOnActivate() {
        guard let state = AppEnvironment.shared?.state else { return }
        state.launchAtLogin.accept(LaunchAtLoginHelper.isEnabled())
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        QuickLookTempStore.shared.removeAll()
        // Drain coalesced order writes before the process dies (bounded wait).
        HistoryFileManager.default.flushHistoryOrderSync(timeout: 1.5)
        #if DEBUG
        if let root = unitTestStorageRoot {
            try? FileManager.default.removeItem(at: root)
            unitTestStorageRoot = nil
            StorageRoot.override = nil
        }
        #endif
    }
    
    func checkLaunchArgs() {
        if CommandLine.arguments.contains("--pasteboard-diagnostics") {
            PasteboardDiagnostics.isEnabled = true
        }
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            do {
                try UITesting.setupUITestEnvironment(
                    launchArgs: CommandLine.arguments,
                    environment: ProcessInfo.processInfo.environment
                )
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        #endif
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
        ClipHotKeys.toggle.changeHotKey(keyCombo: AppEnvironment.shared.settings.toggleHotKey)
        ClipHotKeys.toggle.onDown {
            AppEnvironment.shared.routing.togglePopover()
        }
    }
}

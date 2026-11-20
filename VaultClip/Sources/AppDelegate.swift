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
        applyPreviewStorageRootIfRequested()
        #endif
        _ = SingleInstanceGuard.terminateIfDuplicate()
    }

    #if DEBUG
    /// `--storage-root=PATH` (scripts/ui-preview.sh): isolated history for visual checks.
    /// Refused for the production bundle id so a Debug build never redirects real data.
    private func applyPreviewStorageRootIfRequested() {
        guard !AppIdentity.isProduction,
              let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--storage-root=") }) else { return }
        let path = String(arg.dropFirst("--storage-root=".count))
        guard !path.isEmpty else { return }
        let root = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        StorageRoot.override = root
        StorageRoot.suppressesCapture = true
    }

    /// `--panel-command=<PanelCommandID>` (repeatable), `--context-menu-row=N` and `--dump-layout`
    /// drive UI states for screenshots (scripts/ui-preview.sh).
    private func schedulePreviewPanelScript() {
        let args = CommandLine.arguments
        let commands = args.compactMap { arg -> PanelCommandID? in
            guard arg.hasPrefix("--panel-command=") else { return nil }
            return PanelCommandID(rawValue: String(arg.dropFirst("--panel-command=".count)))
        }
        let menuRow = args.first(where: { $0.hasPrefix("--context-menu-row=") })
            .flatMap { Int($0.dropFirst("--context-menu-row=".count)) }
        func panel() -> HistoryViewController? {
            AppEnvironment.shared.controller?.historyWindowController.contentViewController as? HistoryViewController
        }
        for (index, command) in commands.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 + Double(index) * 0.5) {
                _ = panel()?.performPanelCommand(command)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            guard args.contains("--dump-layout"), let vc = panel() else { return }
            var lines = ["window=\(String(describing: vc.view.window?.frame)) screen=\(String(describing: vc.view.window?.screen?.frame)) visible=\(String(describing: vc.view.window?.screen?.visibleFrame))"]
            lines += NSScreen.screens.map { "screen \($0.frame) visible \($0.visibleFrame)" }
            for sub in vc.view.subviews {
                lines.append("sub \(type(of: sub)) frame=\(sub.frame) fit=\(sub.fittingSize) hidden=\(sub.isHidden)")
            }
            try? lines.joined(separator: "\n").write(toFile: "/tmp/vc-ui-dump.txt", atomically: true, encoding: .utf8)
        }
        if let menuRow {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3 + Double(commands.count) * 0.5) {
                guard let table = panel()?.historyListView, menuRow < table.numberOfRows else { return }
                table.selectRowIndexes(IndexSet(integer: menuRow), byExtendingSelection: false)
                let rect = table.rect(ofRow: menuRow)
                table.buildContextMenu(for: menuRow)
                    .popUp(positioning: nil, at: NSPoint(x: rect.midX, y: rect.midY), in: table)
            }
        }
    }

    private var isPreviewLaunch: Bool {
        !AppIdentity.isProduction && CommandLine.arguments.contains(where: { $0.hasPrefix("--storage-root=") })
    }
    #endif

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
            #if DEBUG
            if isPreviewLaunch {
                if CommandLine.arguments.contains("--open-panel") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        AppEnvironment.shared.routing.togglePopover()
                    }
                    schedulePreviewPanelScript()
                }
                return
            }
            #endif
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

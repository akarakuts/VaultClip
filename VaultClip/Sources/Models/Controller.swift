//
//  Controller.swift
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

class Controller {
    
    // MARK: - Shared instance (legacy — prefer AppEnvironment.shared.routing)

    private static weak var _shared: Controller?

    static var main: Controller {
        if let controller = _shared { return controller }
        if let controller = AppEnvironment.shared?.controller { return controller }
        preconditionFailure("Controller accessed before AppEnvironment.bootstrap()")
    }

    static func installShared(_ controller: Controller?) {
        _shared = controller
    }
    
    
    // MARK: - Attributes
    
    var state: State
    
    /// Must exist for the duration of the application so that the status bar does not disappear.
    let statusItem: NSStatusItem
    
    // Window Controllers
    let historyWindowController: HistoryWindowController
    let previewWindowController: PreviewWindowController
    
    lazy var welcomeWindowController: WelcomeWindowController = {
        return WelcomeWindowController.createWelcomeWindowController()
    }()
    
    lazy var helpWindowController: HelpWindowController = {
        return HelpWindowController.createHelpWindowController()
    }()
    
    lazy var aboutWindowController: AboutWindowController = {
        return AboutWindowController.createAboutWindowController()
    }()
    
    lazy var settingsWindowController: SettingsWindowController = {
        return SettingsWindowController.createSettingsWindowController()
    }()
    
    
    // MARK: - Constructor
    
    init(state: State, settings: Settings) {
        self.state = state
        // Setup status item
        self.statusItem = ClipStatusItem.create()

        // Create history window controller (load window so list UI subscribes before first copy).
        self.historyWindowController = Self.createHistoryWindowController(state: state, settings: settings, disposeBag: state.disposeBag)

        // Create preview window controllers
        self.previewWindowController = Self.createPreviewWindowController(
            state: state,
            previewItem: state.previewHistoryItem,
            disposeBag: state.disposeBag
        )

        self.statusItem.menu = Self.createMenu(settings: settings, state: state, target: self)
        if let button = self.statusItem.button {
            ClipStatusItem.applyPausedAppearance(to: button, isPaused: settings.isCapturePaused)
        }
        configureStatusItemClickMode(settings.statusItemClickMode)
        self.historyWindowController.loadWindow()
    }

    private func configureStatusItemClickMode(_ mode: StatusItemClickMode) {
        guard let button = statusItem.button else { return }
        if StatusItemPresentation.leftClickOpensPanel(mode: mode) {
            statusItem.menu = nil
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        } else {
            button.sendAction(on: [.leftMouseUp])
            statusItem.menu = Self.createMenu(settings: Settings.main, state: state, target: self)
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }
        if event.type == .rightMouseUp
            || event.modifierFlags.contains(.control)
            || event.modifierFlags.contains(.option) {
            let menu = Self.createMenu(settings: Settings.main, state: state, target: self)
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }
        togglePopover()
    }
    
    
    // MARK: - Constructor Helpers
    
    static func createMenu(settings: Settings, state: State, target: AnyObject?) -> NSMenu {
        let menu = NSMenu()
            .with(menuItem: NSMenuItem(title: L10n.menuAbout, action: #selector(showAboutWindow), keyEquivalent: "")
                .with(tag: StatusMenuTag.about.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.aboutButton)
            )
            .with(menuItem: NSMenuItem(title: L10n.menuHelp, action: #selector(showHelpWindow), keyEquivalent: "")
                .with(tag: StatusMenuTag.help.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.helpButton)
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: L10n.menuPreferences, action: #selector(showSettings), keyEquivalent: "")
                .with(tag: StatusMenuTag.preferences.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.preferencesButton)
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: L10n.menuToggleWindow, action: #selector(togglePopover), keyEquivalent: "V")
                .with(tag: StatusMenuTag.toggleWindow.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.toggleHistoryWindowButton)
            )
            .with(menuItem: NSMenuItem(title: L10n.menuPauseCapture, action: #selector(toggleCapturePaused), keyEquivalent: "")
                .with(tag: StatusMenuTag.pauseCapture.rawValue)
            )
            // Launch-at-login and delete-selected moved to Settings (U28).
            .with(menuItem: NSMenuItem(title: L10n.menuClearHistory, action: #selector(clearHistoryClicked), keyEquivalent: "")
                .with(tag: StatusMenuTag.clearHistory.rawValue)
            )
            .with(menuItem: NSMenuItem(title: L10n.menuPosition, action: nil, keyEquivalent: "")
                .with(tag: StatusMenuTag.position.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.positionButton)
                .with(submenu: createWindowPositionSubmenu(settings: settings))
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: L10n.menuQuit, action: #selector(quit), keyEquivalent: "")
                .with(tag: StatusMenuTag.quit.rawValue)
                .with(accessibilityIdentifier: Accessibility.identifiers.quitButton)
        )
        menu.autoenablesItems = false
        
        Self.setMenuItemsTarget(target: target, menu: menu)
        Self.refreshCapturePausedMenu(menu)
        
        state.launchAtLogin
            .subscribe (onNext: {
                menu.item(withTag: StatusMenuTag.launchAtLogin.rawValue)?.state = $0 ? .on : .off
            })
            .disposed(by: state.disposeBag)
        
        state.panelPosition
            .subscribe(onNext: { next in
                PanelPosition.allCases.forEach { pos in
                    menu.item(withTag: StatusMenuTag.position.rawValue)?.submenu?.item(withTag: pos.rawValue)?.state = next == pos ? .on : .off
                }
            })
            .disposed(by: state.disposeBag)
        
        
        state.isHistoryPanelShown
            .subscribe(onNext: {
                let positionMenu = menu.item(withTag: StatusMenuTag.position.rawValue)?.submenu
                positionMenu?.item(withTag: PanelPosition.left.rawValue)?.keyEquivalent = $0 ? Constants.statusItemMenu.leftArrowKeyEquivalent : ""
                positionMenu?.item(withTag: PanelPosition.left.rawValue)?.keyEquivalentModifierMask = NSEvent.ModifierFlags(arrayLiteral: .control, .option, .command)
                
                positionMenu?.item(withTag: PanelPosition.right.rawValue)?.keyEquivalent = $0 ? Constants.statusItemMenu.rightArrowKeyEquivalent : ""
                positionMenu?.item(withTag: PanelPosition.right.rawValue)?.keyEquivalentModifierMask = NSEvent.ModifierFlags(arrayLiteral: .control, .option, .command)
                
                positionMenu?.item(withTag: PanelPosition.top.rawValue)?.keyEquivalent = $0 ? Constants.statusItemMenu.upArrowKeyEquivalent : ""
                positionMenu?.item(withTag: PanelPosition.top.rawValue)?.keyEquivalentModifierMask = NSEvent.ModifierFlags(arrayLiteral: .control, .option, .command)
                
                positionMenu?.item(withTag: PanelPosition.bottom.rawValue)?.keyEquivalent = $0 ? Constants.statusItemMenu.downArrowKeyEquivalent : ""
                positionMenu?.item(withTag: PanelPosition.bottom.rawValue)?.keyEquivalentModifierMask = NSEvent.ModifierFlags(arrayLiteral: .control, .option, .command)
                
                menu.item(withTag: StatusMenuTag.deleteSelected.rawValue)?.isEnabled = $0
                menu.item(withTag: StatusMenuTag.deleteSelected.rawValue)?.keyEquivalentModifierMask = .control
            })
            .disposed(by: state.disposeBag)
        
        return menu
    }
    
    static func createWindowPositionSubmenu(settings: Settings) -> NSMenu {
        let menu = NSMenu(title: "")
        menu.items = PanelPosition.allCases.map({pos in
            return NSMenuItem(title: pos.title, action: #selector(panelPositionSelected(_:)), keyEquivalent: "")
                .with(accessibilityIdentifier: pos.identifier)
                .with(state: settings.panelPosition == pos ? .on : .off)
                .with(tag: pos.rawValue)
        })
        return menu
    }
    
    static func setMenuItemsTarget(target: AnyObject?, menu: NSMenu) {
        for item in menu.items {
            item.target = target
            if let subMenu = item.submenu {
                setMenuItemsTarget(target: target, menu: subMenu)
            }
        }
    }
    
    static func createHistoryWindowController(state: State, settings: Settings, disposeBag: DisposeBag) -> HistoryWindowController {
        let controller = HistoryWindowController.createHistoryWindowController()
        (controller.contentViewController as? HistoryViewController)?
            .configure(state: state, settings: { SettingsPersistence.current() })
        controller
            .subscribeTo(toggle: state.isHistoryPanelShown, state: state)
            .disposed(by: disposeBag)
        controller
            .subscribeFrameTo(position: state.panelPosition.asObservable(), screen: state.currentScreen.asObservable())
            .disposed(by: disposeBag)
        return controller
    }
    
    static func createPreviewWindowController(
        state: State,
        previewItem: BehaviorRelay<HistoryItem?>,
        disposeBag: DisposeBag
    ) -> PreviewWindowController {
        let controller = PreviewWindowController.create(state: state)
        controller
            .subscribeTo(previewItem: previewItem)
            .disposed(by: disposeBag)
        return controller
    }
    
    
    // MARK: - Methods
    @objc func panelPositionSelected(_ sender: NSMenuItem) {
        if let position = PanelPosition(rawValue: sender.tag) {
            state.panelPosition.accept(position)
        }
        else {
            ClipError(.invalidPanelPosition, localizedDescription: "Received invalid panel position from \(sender)").log(with: ErrorLogger.general)
        }
    }

    @objc func togglePopover() {
        let willShow = !state.isHistoryPanelShown.value
        if willShow {
            state.refreshCurrentScreenFromMouse()
        }
        state.isHistoryPanelShown.accept(willShow)
    }

    @objc func toggleCapturePaused() {
        let paused = !Settings.main.isCapturePaused
        SettingsPersistence.apply { $0.isCapturePaused = paused }
        if let button = statusItem.button {
            ClipStatusItem.applyPausedAppearance(to: button, isPaused: paused)
        }
        if let menu = statusItem.menu {
            Self.refreshCapturePausedMenu(menu)
        }
    }

    private static func refreshCapturePausedMenu(_ menu: NSMenu) {
        let paused = Settings.main.isCapturePaused
        menu.item(withTag: StatusMenuTag.pauseCapture.rawValue)?.title =
            paused ? L10n.menuResumeCapture : L10n.menuPauseCapture
    }
    
    @objc func deleteSelectedClicked() {
        // Route straight to the view controller; synthesising a global key event made the
        // delete depend on the panel being key and the CGEvent tap being alive (P9/D2).
        (historyWindowController.contentViewController as? HistoryViewController)?.deleteSelected()
    }
    
    @objc func clearHistoryClicked() {
        let response = PanelFocusGuard.withSuspended { () -> NSApplication.ModalResponse in
            let alert = NSAlert()
            alert.messageText = L10n.alertClearHistoryTitle
            alert.informativeText = L10n.alertClearHistoryMessage
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.menuClearHistory)
            alert.addButton(withTitle: L10n.menuClearAll)
            alert.addButton(withTitle: L10n.commonCancel)
            return alert.runModal()
        }
        switch response {
        case .alertFirstButtonReturn:
            state.history.clear(nonFavoritesOnly: true)
        case .alertSecondButtonReturn:
            state.history.clear(nonFavoritesOnly: false)
        default:
            break
        }
    }
    
    @objc func showHelpWindow() {
        showWindowIfNeeded(helpWindowController)
    }
    
    @objc func showAboutWindow() {
        showWindowIfNeeded(aboutWindowController)
    }
    
    @objc func showSettings() {
        (settingsWindowController.contentViewController as? SettingsTabViewController)?
            .configure(state: state)
        showWindowIfNeeded(settingsWindowController)
    }

    private func showWindowIfNeeded(_ windowController: NSWindowController) {
        if windowController.window?.isVisible != true {
            windowController.showWindow(nil)
            windowController.window?.center()
        }
        AppActivation.activateFrontmostApplication()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func launchAtLogin() {
        let wantsLaunchAtLogin = !state.launchAtLogin.value
        let succeeded = wantsLaunchAtLogin ? LaunchAtLoginHelper.enable() : LaunchAtLoginHelper.disable()
        guard succeeded else { return }
        state.launchAtLogin.accept(wantsLaunchAtLogin)
    }
}

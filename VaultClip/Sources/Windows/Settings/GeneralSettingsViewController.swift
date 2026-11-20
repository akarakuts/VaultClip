//
//  GeneralSettingsViewController.swift
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

class GeneralSettingsViewController: NSViewController {
    
    
    @IBOutlet var maxHistoryItemsPopUpButton: NSPopUpButton!
    @IBOutlet var showsRichTextButton: NSButton!
    @IBOutlet var pastesRichTextButton: NSButton!

    private var maxItemSizePopUpButton: NSPopUpButton!
    private var maxItemSizeLabel: NSTextField!
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeUI()
        setupMaxHistoryItemsPopUpButton()
        setupMaxItemSizeControls()
        setupPasswordAuthControls()
        setupRetentionControls()
        setupShowsRichTextButton()
        setupPastesRichTextButton()
    }
    
    // MARK: Setup view

    private func localizeUI() {
        for subview in view.subviews {
            if let field = subview as? NSTextField {
                switch field.stringValue {
                case "Maximum number of items saved:":
                    field.stringValue = L10n.settingsMaxItemsLabel
                case "Rich text:":
                    field.stringValue = L10n.settingsRichTextLabel
                default:
                    break
                }
            }
            if let button = subview as? NSButton {
                switch button.title {
                case "Shows rich text":
                    button.title = L10n.settingsShowsRichText
                case "Pastes rich text":
                    button.title = L10n.settingsPastesRichText
                default:
                    break
                }
            }
        }
    }
    
    private func setupMaxHistoryItemsPopUpButton() {
        maxHistoryItemsPopUpButton.removeAllItems()
        for val in Constants.settings.maxHistoryItemsOptions {
            maxHistoryItemsPopUpButton.addItem(withTitle: "\(val)")
        }
        
        AppEnvironment.shared.state.history.maxItems.subscribe(onNext: onMaxHistoryItems).disposed(by: disposeBag)
        
        maxHistoryItemsPopUpButton.target = self
        maxHistoryItemsPopUpButton.action = #selector(onMaxItemsSelected)
        maxHistoryItemsPopUpButton.isEnabled = true
        maxHistoryItemsPopUpButton.autoenablesItems = true
    }
    
    private func setupMaxItemSizeControls() {
        let label = NSTextField(labelWithString: L10n.settingsMaxItemSizeLabel)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        maxItemSizeLabel = label

        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.removeAllItems()
        for mb in Constants.settings.maxItemSizeMBOptions {
            if mb == 0 {
                popup.addItem(withTitle: L10n.settingsMaxItemSizeUnlimited)
            } else {
                popup.addItem(withTitle: L10n.settingsMaxItemSizeMB(mb))
            }
        }
        popup.target = self
        popup.action = #selector(onMaxItemSizeSelected)
        view.addSubview(popup)
        maxItemSizePopUpButton = popup

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: maxHistoryItemsPopUpButton.leadingAnchor),
            label.topAnchor.constraint(equalTo: maxHistoryItemsPopUpButton.bottomAnchor, constant: 12),
            popup.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            popup.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            popup.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
        ])

        selectMaxItemSize(Settings.main.maxItemSizeMB)
    }

    private func setupPasswordAuthControls() {
        let authButton = NSButton(checkboxWithTitle: L10n.settingsPasswordAuth, target: self, action: #selector(onPasswordAuthToggled))
        authButton.translatesAutoresizingMaskIntoConstraints = false
        authButton.state = Settings.main.requiresPasswordAuthentication ? .on : .off
        view.addSubview(authButton)

        let graceLabel = NSTextField(labelWithString: L10n.settingsPasswordAuthGrace)
        graceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(graceLabel)

        let gracePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        gracePopup.translatesAutoresizingMaskIntoConstraints = false
        gracePopup.removeAllItems()
        for minutes in [0, 1, 5, 15] {
            if minutes == 0 {
                gracePopup.addItem(withTitle: L10n.settingsPasswordAuthGraceImmediate)
            } else {
                gracePopup.addItem(withTitle: L10n.settingsPasswordAuthGraceMinutes(minutes))
            }
        }
        let graceOptions = [0, 1, 5, 15]
        let graceIndex = graceOptions.firstIndex(of: Settings.main.passwordAuthGraceMinutes) ?? 2
        gracePopup.selectItem(at: graceIndex)
        gracePopup.target = self
        gracePopup.action = #selector(onPasswordAuthGraceSelected)
        gracePopup.tag = 2901
        view.addSubview(gracePopup)

        NSLayoutConstraint.activate([
            authButton.leadingAnchor.constraint(equalTo: maxItemSizeLabel.leadingAnchor),
            authButton.topAnchor.constraint(equalTo: maxItemSizeLabel.bottomAnchor, constant: 14),
            graceLabel.leadingAnchor.constraint(equalTo: authButton.leadingAnchor),
            graceLabel.topAnchor.constraint(equalTo: authButton.bottomAnchor, constant: 8),
            gracePopup.leadingAnchor.constraint(equalTo: graceLabel.trailingAnchor, constant: 8),
            gracePopup.centerYAnchor.constraint(equalTo: graceLabel.centerYAnchor),
        ])
    }

    private func selectMaxItemSize(_ mb: Int) {
        let options = Constants.settings.maxItemSizeMBOptions
        let index = options.firstIndex(of: mb) ?? options.firstIndex(of: Constants.settings.maxItemSizeMBDefault) ?? 0
        if index != maxItemSizePopUpButton.indexOfSelectedItem {
            maxItemSizePopUpButton.selectItem(at: index)
        }
    }

    private func setupShowsRichTextButton() {
        AppEnvironment.shared.state.showsRichText.subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
        showsRichTextButton.target = self
        showsRichTextButton.action = #selector(onShowsRichTextButtonClicked)
    }
    
    private func setupPastesRichTextButton() {
        AppEnvironment.shared.state.pastesRichText.subscribe(onNext: onPastesRichText).disposed(by: disposeBag)
        
        pastesRichTextButton.target = self
        pastesRichTextButton.action = #selector(onPastesRichTextButtonClicked)
    }
    
    // MARK: Bind to settings
    
    private func onMaxHistoryItems(_ maxItems: Int) {
        let newIndex = Constants.settings.maxHistoryItemsOptions.firstIndex(of: maxItems) ?? Constants.settings.maxHistoryItemsDefaultIndex
        if newIndex != maxHistoryItemsPopUpButton.indexOfSelectedItem {
            maxHistoryItemsPopUpButton.selectItem(at: newIndex)
        }
    }
    
    private func onShowsRichText(_ showsRichText: Bool) {
        showsRichTextButton.state = showsRichText ? .on : .off
    }
    
    private func onPastesRichText(_ pastesRichText: Bool) {
        pastesRichTextButton.state = pastesRichText ? .on : .off
    }
    
    // MARK: Handle Actions
    
    @objc private func onMaxItemsSelected() {
        let history = AppEnvironment.shared.state.history
        let selected = Constants.settings.maxHistoryItemsOptions[maxHistoryItemsPopUpButton.indexOfSelectedItem]
        let pruneCount = history.itemsToPrune(forNewMax: selected)
        if pruneCount > 0 {
            let response = PanelFocusGuard.withSuspended { () -> NSApplication.ModalResponse in
                let alert = NSAlert()
                alert.messageText = L10n.alertReduceHistoryTitle
                alert.informativeText = L10n.alertReduceHistoryMessage(pruneCount)
                alert.addButton(withTitle: L10n.commonContinue)
                alert.addButton(withTitle: L10n.commonCancel)
                alert.alertStyle = .warning
                return alert.runModal()
            }
            if response != .alertFirstButtonReturn {
                onMaxHistoryItems(SettingsPersistence.current().maxHistory)
                return
            }
        }
        history.setMaxItems(selected)
    }

    @objc private func onMaxItemSizeSelected() {
        let index = maxItemSizePopUpButton.indexOfSelectedItem
        guard Constants.settings.maxItemSizeMBOptions.indices.contains(index) else { return }
        SettingsPersistence.apply { $0.maxItemSizeMB = Constants.settings.maxItemSizeMBOptions[index] }
    }

    @objc private func onPasswordAuthToggled(_ sender: NSButton) {
        SettingsPersistence.apply { $0.requiresPasswordAuthentication = sender.state == .on }
    }

    @objc private func onPasswordAuthGraceSelected(_ sender: NSPopUpButton) {
        let options = [0, 1, 5, 15]
        guard options.indices.contains(sender.indexOfSelectedItem) else { return }
        SettingsPersistence.apply { $0.passwordAuthGraceMinutes = options[sender.indexOfSelectedItem] }
    }

    private func setupRetentionControls() {
        let label = NSTextField(labelWithString: L10n.settingsRetention)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.translatesAutoresizingMaskIntoConstraints = false
        let options = [0, 1, 7, 30, 90]
        for days in options {
            if days == 0 {
                popup.addItem(withTitle: L10n.settingsRetentionNever)
            } else {
                popup.addItem(withTitle: L10n.settingsRetentionDays(days))
            }
        }
        let index = options.firstIndex(of: Settings.main.retentionDays) ?? 0
        popup.selectItem(at: index)
        popup.target = self
        popup.action = #selector(onRetentionSelected)
        view.addSubview(popup)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: maxItemSizeLabel.leadingAnchor),
            label.topAnchor.constraint(equalTo: maxItemSizeLabel.bottomAnchor, constant: 90),
            popup.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            popup.centerYAnchor.constraint(equalTo: label.centerYAnchor),
        ])
    }

    @objc private func onRetentionSelected(_ sender: NSPopUpButton) {
        let options = [0, 1, 7, 30, 90]
        guard options.indices.contains(sender.indexOfSelectedItem) else { return }
        SettingsPersistence.apply { $0.retentionDays = options[sender.indexOfSelectedItem] }
        AppEnvironment.shared.state.history.purgeExpiredItems()
    }
    
    @objc private func onShowsRichTextButtonClicked() {
        AppEnvironment.shared.state.showsRichText.accept(showsRichTextButton.state == .on)
    }
    
    @objc private func onPastesRichTextButtonClicked() {
        AppEnvironment.shared.state.pastesRichText.accept(pastesRichTextButton.state == .on)
    }
}

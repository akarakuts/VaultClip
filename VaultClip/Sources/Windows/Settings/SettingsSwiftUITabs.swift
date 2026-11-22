//
// SettingsSwiftUITabs — Form-based settings panes hosted in NSTabViewController (U29/U30).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import HotKey
import ServiceManagement
import SwiftUI

struct SettingsGeneralTab: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Toggle(L10n.menuLaunchAtLogin, isOn: launchAtLoginBinding)
                Text(L10n.settingsLaunchAtLoginHint)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            Section {
                Picker(L10n.settingsStatusClick, selection: $store.statusItemClickMode) {
                    Text(L10n.settingsStatusClickPanel).tag(StatusItemClickMode.openPanel)
                    Text(L10n.settingsStatusClickMenu).tag(StatusItemClickMode.openMenu)
                }
                Toggle(L10n.settingsShowRecentMenu, isOn: $store.showsRecentInMenu)
                Stepper(value: $store.recentMenuCount, in: 1...15) {
                    Text(L10n.settingsRecentCount(store.recentMenuCount))
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    PasteboardDiagnostics.log("launch-at-login: \(error)")
                }
            }
        )
    }
}

struct SettingsPanelTab: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Picker(L10n.menuPosition, selection: $store.panelPosition) {
                    ForEach(PanelPosition.allCases, id: \.self) { pos in
                        Text(pos.title).tag(pos)
                    }
                }
                HStack {
                    Text(L10n.settingsWidth)
                    Slider(value: $store.panelEdgeWidth, in: 320...900, step: 10)
                    Text("\(Int(store.panelEdgeWidth))").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
                HStack {
                    Text(L10n.settingsHeight)
                    Slider(value: $store.panelEdgeHeight, in: 240...900, step: 10)
                    Text("\(Int(store.panelEdgeHeight))").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
            }
            Section {
                Picker(L10n.settingsPanelAppearance, selection: $store.panelAppearance) {
                    ForEach(PanelAppearance.allCases, id: \.self) { theme in
                        Text(theme.settingsTitle).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(Accessibility.identifiers.settingsPanelAppearancePicker)
                Text(L10n.settingsPanelAppearanceFootnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if store.panelAppearance == .liquidGlass,
                   !PanelChromeStyleResolver.liquidGlassMaterialIsPublicOnRunningOS {
                    Text(L10n.settingsPanelAppearanceLiquidGlassFallback)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Picker(L10n.settingsTextSize, selection: $store.panelTextSize) {
                    ForEach(TextSizePreference.allCases, id: \.self) { size in
                        Text(size.rawValue.uppercased()).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                Toggle(L10n.settingsMonospaced, isOn: $store.usesMonospacedContentFont)
                Toggle(L10n.settingsGroupByDate, isOn: $store.groupHistoryByDate)
                Toggle(L10n.settingsShowFilterBar, isOn: $store.showsFilterBarPreference)
                Toggle(L10n.settingsShowKeyHints, isOn: $store.showKeyHints)
            }
            Section {
                Toggle(L10n.settingsShowPreview, isOn: $store.previewVisible)
                Picker(L10n.settingsPreviewPlacement, selection: $store.previewPlacement) {
                    Text(L10n.settingsPreviewAutomatic).tag(PreviewPlacement.automatic)
                    Text(L10n.settingsPreviewTrailing).tag(PreviewPlacement.trailing)
                    Text(L10n.settingsPreviewBottom).tag(PreviewPlacement.bottom)
                }
                Toggle(L10n.settingsResetFiltersOnClose, isOn: $store.resetFiltersOnClose)
                Toggle(L10n.settingsReopenLastTab, isOn: $store.reopenLastTab)
                Toggle(L10n.settingsSelectSecondItem, isOn: $store.selectSecondItem)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

struct SettingsPasteTab: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Toggle(L10n.settingsPastesRichText, isOn: $store.pastesRichText)
                Toggle(L10n.settingsShowsRichText, isOn: $store.showsRichText)
                Picker(L10n.settingsMultiPasteSeparator, selection: $store.multiPasteSeparator) {
                    Text(L10n.settingsSepNewline).tag(MultiPasteSeparator.newline)
                    Text(L10n.settingsSepBlankLine).tag(MultiPasteSeparator.blankLine)
                    Text(L10n.settingsSepSpace).tag(MultiPasteSeparator.space)
                    Text(L10n.settingsSepComma).tag(MultiPasteSeparator.comma)
                    Text(L10n.settingsSepTab).tag(MultiPasteSeparator.tab)
                }
                Picker(L10n.settingsClearClipboardAfterPassword, selection: $store.passwordClipboardClearSeconds) {
                    Text(L10n.settingsOff).tag(0)
                    Text("30").tag(30)
                    Text("60").tag(60)
                    Text("90").tag(90)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

struct SettingsHistoryTab: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Stepper(value: $store.maxHistory, in: 10...5000, step: 10) {
                    Text("\(L10n.settingsMaxItemsLabel) \(store.maxHistory)")
                }
                Stepper(value: $store.maxItemSizeMB, in: 1...100) {
                    Text(L10n.settingsMaxItemSizeMB(store.maxItemSizeMB))
                }
                Stepper(value: $store.retentionDays, in: 0...365) {
                    let days = store.retentionDays == 0 ? L10n.settingsOff : "\(store.retentionDays)"
                    Text(L10n.settingsDeleteOlderThan(days))
                }
                Text(L10n.settingsRetentionLastUsedHint)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

struct SettingsPrivacyTab: View {
    @Bindable var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Toggle(L10n.menuPauseCapture, isOn: $store.isCapturePaused)
                Toggle(L10n.settingsRequireAuth, isOn: $store.requiresPasswordAuthentication)
                Stepper(value: $store.passwordAuthGraceMinutes, in: 0...120) {
                    Text(L10n.settingsAuthGrace(store.passwordAuthGraceMinutes))
                }
                Text(L10n.settingsAuthGraceHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Toggle(L10n.settingsHideFromCapture, isOn: $store.hidesPanelFromScreenCapture)
                Text(L10n.settingsHideFromCaptureHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section(L10n.settingsExcludedApps) {
                Text(L10n.settingsExcludedAppsHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ForEach(store.excludedBundleIds, id: \.self) { id in
                    HStack {
                        Image(nsImage: SourceAppIconProvider.icon(forBundleId: id))
                            .resizable()
                            .frame(width: 16, height: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(SourceAppDisplayName.name(forBundleId: id))
                            Text(id).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            store.excludedBundleIds = ExcludedAppsModel.remove(id, from: store.excludedBundleIds)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(L10n.settingsPrivacyRemove)
                    }
                }
                Button(L10n.settingsPrivacyAdd) { chooseApp() }
                DisclosureGroup(L10n.settingsAlwaysExcluded) {
                    ForEach(HistoryPasteboardPolicy.bundleIdDenylist.sorted(), id: \.self) { id in
                        Text("\(SourceAppDisplayName.name(forBundleId: id)) — \(id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let bid = Bundle(url: url)?.bundleIdentifier else { return }
        store.excludedBundleIds = ExcludedAppsModel.add(
            bid,
            to: store.excludedBundleIds,
            selfBundleId: AppIdentity.bundleIdentifier
        )
    }
}

struct SettingsShortcutsTab: View {
    @Bindable var store: SettingsStore
    // The app's `State` class would otherwise hide SwiftUI's property wrapper.
    @SwiftUI.State private var capturePhase: HotKeyCapturePhase = .idle
    @SwiftUI.State private var label: String = ""

    init(store: SettingsStore) {
        self.store = store
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(L10n.settingsHotKey)
                    Spacer()
                    Text(displayLabel)
                        .foregroundStyle(capturePhase == .listening ? .secondary : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))
                        .onTapGesture {
                            capturePhase = .listening
                            label = L10n.settingsHotkeyPress
                        }
                }
                if case .invalid(let message) = capturePhase {
                    Text(message).font(.callout).foregroundStyle(.red)
                }
                Text(L10n.settingsHotkeyCaptureHint)
                .font(.callout)
                .foregroundStyle(.secondary)
                Text(L10n.settingsHotkeyListHint)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            Section(L10n.settingsPanelCommands) {
                ForEach(PanelCommandRegistry.all.prefix(24), id: \.id) { command in
                    HStack {
                        Text(command.title)
                        Spacer()
                        Text(command.bindings.first?.chord.displayString ?? "—")
                            .foregroundStyle(.secondary)
                            .monospaced()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .onAppear { label = format(store.toggleHotKey) }
        .background(HotKeyCaptureMonitor(phase: $capturePhase, label: $label, store: store))
    }

    private var displayLabel: String {
        if capturePhase == .listening { return label }
        return label.isEmpty ? format(store.toggleHotKey) : label
    }

    private func format(_ combo: KeyCombo) -> String {
        let keyStrings = stringifyKeys([combo.key].compactMap { $0 })
        let modifierStrings = combo.modifiers.toStringCharacters()
        return (modifierStrings + keyStrings).joined(separator: "+")
    }
}

private struct HotKeyCaptureMonitor: NSViewRepresentable {
    @Binding var phase: HotKeyCapturePhase
    @Binding var label: String
    var store: SettingsStore

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.phase = $phase
        context.coordinator.label = $label
        context.coordinator.store = store
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(phase: $phase, label: $label, store: store)
    }

    final class Coordinator {
        var phase: Binding<HotKeyCapturePhase>
        var label: Binding<String>
        var store: SettingsStore
        private var monitor: Any?

        init(phase: Binding<HotKeyCapturePhase>, label: Binding<String>, store: SettingsStore) {
            self.phase = phase
            self.label = label
            self.store = store
        }

        func install() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.phase.wrappedValue == .listening else { return event }
                if event.keyCode == 53 {
                    self.phase.wrappedValue = .idle
                    self.label.wrappedValue = self.format(self.store.toggleHotKey)
                    return nil
                }
                if event.keyCode == 51 {
                    let combo = KeyCombo(key: .v, modifiers: [.command, .shift])
                    self.apply(combo)
                    return nil
                }
                guard let key = Key(carbonKeyCode: UInt32(event.keyCode)) else {
                    self.phase.wrappedValue = .invalid(message: HotKeyValidationError.invalidKey.localizedMessage)
                    return nil
                }
                switch HotKeyValidator.validate(key: key, modifiers: event.modifierFlags) {
                case .success(let combo):
                    self.apply(combo)
                case .failure(let error):
                    self.phase.wrappedValue = .invalid(message: error.localizedMessage)
                }
                return nil
            }
        }

        private func apply(_ combo: KeyCombo) {
            Task { @MainActor in
                store.toggleHotKey = combo
                ClipHotKeys.toggle.changeHotKey(keyCombo: combo)
                phase.wrappedValue = .valid
                label.wrappedValue = format(combo)
            }
        }

        private func format(_ combo: KeyCombo) -> String {
            let keyStrings = stringifyKeys([combo.key].compactMap { $0 })
            let modifierStrings = combo.modifiers.toStringCharacters()
            return (modifierStrings + keyStrings).joined(separator: "+")
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}

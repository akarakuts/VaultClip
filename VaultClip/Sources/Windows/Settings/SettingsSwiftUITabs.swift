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
                Text(SettingsUICopy.t(
                    "Requires approval in System Settings on some macOS versions.",
                    "На некоторых версиях macOS нужно разрешение в Системных настройках."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            Section {
                Picker(SettingsUICopy.t("Menu bar icon click", "Клик по значку"), selection: $store.statusItemClickMode) {
                    Text(SettingsUICopy.t("Open panel", "Открыть панель")).tag(StatusItemClickMode.openPanel)
                    Text(SettingsUICopy.t("Open menu", "Открыть меню")).tag(StatusItemClickMode.openMenu)
                }
                Toggle(SettingsUICopy.t("Show recent in menu", "Недавние в меню"), isOn: $store.showsRecentInMenu)
                Stepper(value: $store.recentMenuCount, in: 1...15) {
                    Text("\(SettingsUICopy.t("Recent count", "Количество")): \(store.recentMenuCount)")
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
                    if enabled { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
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
                    Text(SettingsUICopy.t("Width", "Ширина"))
                    Slider(value: $store.panelEdgeWidth, in: 320...900, step: 10)
                    Text("\(Int(store.panelEdgeWidth))").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
                HStack {
                    Text(SettingsUICopy.t("Height", "Высота"))
                    Slider(value: $store.panelEdgeHeight, in: 240...900, step: 10)
                    Text("\(Int(store.panelEdgeHeight))").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
            }
            Section {
                Picker(SettingsUICopy.t("Text size", "Размер текста"), selection: $store.panelTextSize) {
                    ForEach(TextSizePreference.allCases, id: \.self) { size in
                        Text(size.rawValue.uppercased()).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                Toggle(SettingsUICopy.t("Monospaced content", "Моноширинный шрифт"), isOn: $store.usesMonospacedContentFont)
                Toggle(SettingsUICopy.t("Group by date", "Группировать по дате"), isOn: $store.groupHistoryByDate)
                Toggle(SettingsUICopy.t("Show filter bar", "Показывать панель фильтров"), isOn: $store.showsFilterBarPreference)
                Toggle(SettingsUICopy.t("Show key hints", "Показывать подсказки клавиш"), isOn: $store.showKeyHints)
            }
            Section {
                Toggle(SettingsUICopy.t("Show preview", "Показывать превью"), isOn: $store.previewVisible)
                Picker(SettingsUICopy.t("Preview placement", "Расположение превью"), selection: $store.previewPlacement) {
                    Text(SettingsUICopy.t("Automatic", "Авто")).tag(PreviewPlacement.automatic)
                    Text(SettingsUICopy.t("Trailing", "Справа")).tag(PreviewPlacement.trailing)
                    Text(SettingsUICopy.t("Bottom", "Снизу")).tag(PreviewPlacement.bottom)
                }
                Toggle(SettingsUICopy.t("Reset filters on close", "Сбрасывать фильтры при закрытии"), isOn: $store.resetFiltersOnClose)
                Toggle(SettingsUICopy.t("Reopen last tab", "Открывать последнюю вкладку"), isOn: $store.reopenLastTab)
                Toggle(SettingsUICopy.t("Select second item", "Выделять второй элемент"), isOn: $store.selectSecondItem)
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
                Picker(SettingsUICopy.t("Multi-paste separator", "Разделитель для нескольких"), selection: $store.multiPasteSeparator) {
                    Text(SettingsUICopy.t("Newline", "Перевод строки")).tag(MultiPasteSeparator.newline)
                    Text(SettingsUICopy.t("Blank line", "Пустая строка")).tag(MultiPasteSeparator.blankLine)
                    Text(SettingsUICopy.t("Space", "Пробел")).tag(MultiPasteSeparator.space)
                    Text(SettingsUICopy.t("Comma", "Запятая")).tag(MultiPasteSeparator.comma)
                    Text(SettingsUICopy.t("Tab", "Табуляция")).tag(MultiPasteSeparator.tab)
                }
                Picker(SettingsUICopy.t("Clear clipboard after password", "Очищать буфер после пароля"), selection: $store.passwordClipboardClearSeconds) {
                    Text(SettingsUICopy.t("Off", "Выкл")).tag(0)
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
                    Text("\(SettingsUICopy.t("Max item size", "Макс. размер элемента")): \(store.maxItemSizeMB) MB")
                }
                Stepper(value: $store.retentionDays, in: 0...365) {
                    let days = store.retentionDays == 0
                        ? SettingsUICopy.t("Off", "Выкл")
                        : "\(store.retentionDays)"
                    Text("\(SettingsUICopy.t("Delete older than", "Удалять старше")): \(days)")
                }
                Text(SettingsUICopy.t(
                    "Retention uses last used time.",
                    "Срок хранения считается по последнему использованию."
                ))
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
                Toggle(SettingsUICopy.t("Require Touch ID / password", "Требовать Touch ID или пароль"), isOn: $store.requiresPasswordAuthentication)
                Stepper(value: $store.passwordAuthGraceMinutes, in: 0...120) {
                    Text("\(SettingsUICopy.t("Don't ask again for", "Не спрашивать повторно")): \(store.passwordAuthGraceMinutes) \(SettingsUICopy.t("min", "мин"))")
                }
                Toggle(SettingsUICopy.t("Hide panel from screen capture", "Скрывать панель от записи экрана"), isOn: $store.hidesPanelFromScreenCapture)
            }
            Section(SettingsUICopy.t("Excluded apps", "Исключённые приложения")) {
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
                    }
                }
                Button(L10n.settingsPrivacyAdd) { chooseApp() }
                DisclosureGroup(SettingsUICopy.t("Always excluded", "Всегда исключаются")) {
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
    @State private var capturePhase: HotKeyCapturePhase = .idle
    @State private var label: String = ""

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
                            label = SettingsUICopy.t("Press shortcut…", "Нажмите сочетание…")
                        }
                }
                if case .invalid(let message) = capturePhase {
                    Text(message).font(.callout).foregroundStyle(.red)
                }
                Text(SettingsUICopy.t(
                    "Click the field and press a shortcut. Esc cancels, ⌫ restores ⌘⇧V.",
                    "Нажмите на поле и введите сочетание. Esc — отмена, ⌫ — вернуть ⌘⇧V."
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            Section(SettingsUICopy.t("Panel commands", "Команды панели")) {
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

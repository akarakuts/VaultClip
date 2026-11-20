//
// PrivacySettingsViewController — user denylist of apps to ignore (T33).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class PrivacySettingsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private let addButton = NSButton(title: L10n.settingsPrivacyAdd, target: nil, action: nil)
    private let removeButton = NSButton(title: L10n.settingsPrivacyRemove, target: nil, action: nil)

    private var ids: [String] = Settings.main.excludedBundleIds

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 280))
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        table.headerView = nil
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        col.width = 380
        table.addTableColumn(col)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 28
        addButton.target = self
        addButton.action = #selector(addApp)
        removeButton.target = self
        removeButton.action = #selector(removeSelected)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        view.addSubview(addButton)
        view.addSubview(removeButton)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scroll.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -12),
            addButton.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 8),
            removeButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor)
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int { ids.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = ids[row]
        let cell = NSTableCellView()
        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            icon.image = NSWorkspace.shared.icon(forFile: url.path)
        }
        let label = NSTextField(labelWithString: "\(appName(for: id)) — \(id)")
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(icon)
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4)
        ])
        return cell
    }

    private func appName(for bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return bundleId
    }

    @objc private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["app"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        let response = PanelFocusGuard.withSuspended { panel.runModal() }
        guard response == .OK, let url = panel.url,
              let bundleId = Bundle(url: url)?.bundleIdentifier else { return }
        guard !ids.contains(bundleId) else { return }
        ids.append(bundleId)
        persist()
        table.reloadData()
    }

    @objc private func removeSelected() {
        let row = table.selectedRow
        guard ids.indices.contains(row) else { return }
        ids.remove(at: row)
        persist()
        table.reloadData()
    }

    private func persist() {
        SettingsPersistence.apply { $0.excludedBundleIds = ids }
    }
}

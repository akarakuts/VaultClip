//
//  HistoryItemBaseCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

/// Abstract base class for all history collection view items.
class HistoryItemBaseCellView: NSTableCellView {
    
    static var contentViewInsets: NSEdgeInsets { PanelChrome.Metrics.cardInsets }
    static var sourceAppIconSize: CGFloat { PanelChrome.Metrics.sourceAppIconSize }
    static var sourceAppIconTrailingInset: CGFloat { PanelChrome.Metrics.sourceAppIconTrailingInset }
    static var sourceAppIconSpacing: CGFloat { PanelChrome.Metrics.sourceAppIconSpacing }
    
    class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("HistoryItemBaseCellView")
    }
    
    let contentView = HistoryItemContentView(frame: .zero)
    let shortcutTextView = HistoryItemCellTextView(frame: .zero)
    let itemTextView = HistoryItemCellTextView(frame: .zero)
    let sourceAppIconView = NSImageView(frame: .zero)
    
    weak var hostTableView: HistoryTableView?
    var displayedRow: Int = -1
    
    private var isRowSelected = false
    private var isRowHovered = false
    private var shortcutRowIndex: Int?
    
    override func updateLayer() {
        super.updateLayer()
        applyRowAppearance()
    }
    
    func setHighlight(isSelected: Bool) {
        isRowSelected = isSelected
        applyRowAppearance()
    }
    
    private func setHover(_ hovered: Bool) {
        guard isRowHovered != hovered else { return }
        isRowHovered = hovered
        applyRowAppearance()
    }
    
    private func applyRowAppearance() {
        layer?.backgroundColor = PanelChrome.Colors.rowOuterFill(
            isSelected: isRowSelected,
            isHovered: isRowHovered
        ).cgColor
        
        contentView.isRowSelected = isRowSelected
        updateShortcutAppearance()
    }
    
    private func updateShortcutAppearance() {
        guard let index = shortcutRowIndex, index < 10 else { return }
        
        if isRowSelected {
            shortcutTextView.backgroundColor = PanelChrome.Colors.shortcutBackgroundSelected
            shortcutTextView.attributedText = NSAttributedString(
                string: "⌘ + \(index)",
                attributes: Self.shortcutAttributes(selected: true)
            )
        } else {
            shortcutTextView.backgroundColor = PanelChrome.Colors.accent
            shortcutTextView.attributedText = NSAttributedString(
                string: "⌘ + \(index)",
                attributes: Self.shortcutAttributes(selected: false)
            )
        }
    }
    
    private static func shortcutAttributes(selected: Bool) -> [NSAttributedString.Key: Any] {
        [
            .font: PanelChrome.Typography.body,
            .foregroundColor: selected
                ? PanelChrome.Colors.shortcutForegroundSelected
                : PanelChrome.Colors.shortcutForegroundNormal,
        ]
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        addSubview(contentView)
        contentView.addSubview(itemTextView)
        contentView.addSubview(shortcutTextView)
        
        wantsLayer = true
        layer?.cornerRadius = PanelChrome.Metrics.rowOuterRadius
        itemTextView.drawsBackground = false
        itemTextView.setAccessibilityIdentifier(Accessibility.identifiers.historyItemTextView)
        configureListTextView(itemTextView)
        
        setupSourceAppIconView()
        setupContentView()
        setupShortcutTextView()
        installTrackingAreas()
    }
    
    func bindHost(_ tableView: HistoryTableView, row: Int, historyItem: HistoryItem) {
        hostTableView = tableView
        displayedRow = row
    }
    
    private func configureListTextView(_ textView: HistoryItemCellTextView) {
        textView.alignment = .left
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
    }
    
    private func installTrackingAreas() {
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        installTrackingAreas()
    }
    
    override func mouseEntered(with event: NSEvent) {
        setHover(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        setHover(false)
    }
    
    func setupSourceAppIconView() {
        sourceAppIconView.translatesAutoresizingMaskIntoConstraints = false
        sourceAppIconView.imageScaling = .scaleProportionallyDown
        sourceAppIconView.wantsLayer = true
        sourceAppIconView.layer?.cornerRadius = PanelChrome.Metrics.sourceAppIconCornerRadius
        sourceAppIconView.layer?.backgroundColor = PanelChrome.Colors.sourceIconBackdrop.cgColor
        sourceAppIconView.layer?.masksToBounds = true
        sourceAppIconView.layer?.zPosition = 2
        contentView.addSubview(sourceAppIconView)
        
        sourceAppIconView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: Self.sourceAppIconTrailingInset
        ).isActive = true
        sourceAppIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        sourceAppIconView.widthAnchor.constraint(equalToConstant: Self.sourceAppIconSize).isActive = true
        sourceAppIconView.heightAnchor.constraint(equalToConstant: Self.sourceAppIconSize).isActive = true
    }
    
    func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = PanelChrome.Metrics.cardRadius
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.contentViewInsets.left),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: Self.contentViewInsets.top),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Self.contentViewInsets.right),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Self.contentViewInsets.bottom),
        ])
    }
    
    func setupShortcutTextView() {
        shortcutTextView.translatesAutoresizingMaskIntoConstraints = false
        shortcutTextView.wantsLayer = true
        shortcutTextView.isSelectable = false
        shortcutTextView.textContainer?.lineFragmentPadding = 0
        shortcutTextView.alignment = .right
        shortcutTextView.textContainerInset = PanelChrome.Metrics.shortcutTextInset
        shortcutTextView.layer?.cornerRadius = PanelChrome.Metrics.shortcutCornerRadius
        shortcutTextView.layer?.maskedCorners = .layerMinXMaxYCorner
        shortcutTextView.isHorizontallyResizable = false
        shortcutTextView.isVerticallyResizable = false
        shortcutTextView.backgroundColor = PanelChrome.Colors.accent
        shortcutTextView.layer?.zPosition = 1
        
        NSLayoutConstraint.activate([
            shortcutTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: shortcutTextView.trailingAnchor),
        ])
        shortcutTextView.widthAnchor.constraint(equalToConstant: 0, withIdentifier: "width")?.isActive = true
        shortcutTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func getShortcutTextViewSize() -> NSSize {
        let bRect = shortcutTextView.attributedString().getSingleLineSize()
        let inset = shortcutTextView.textContainerInset
        let lineFragmentPadding = shortcutTextView.textContainer?.lineFragmentPadding ?? 0
        return NSSize(
            width: bRect.width + lineFragmentPadding + inset.width * 2,
            height: bRect.height + inset.height * 2
        )
    }
    
    func updateShortcutTextViewContraints() {
        let size = getShortcutTextViewSize()
        shortcutTextView.constraint(withIdentifier: "width")?.constant = ceil(size.width)
        shortcutTextView.constraint(withIdentifier: "height")?.constant = ceil(size.height)
    }
    
    func setupShortcutTextView(at i: Int, historyItem: HistoryItem) {
        shortcutRowIndex = i
        shortcutTextView.isHidden = i >= 10
        if i < 10 {
            updateShortcutAppearance()
        }
        updateShortcutTextViewContraints()
        configureSourceAppIcon(for: historyItem)
        if let table = hostTableView {
            bindHost(table, row: i, historyItem: historyItem)
        }
    }
    
    func configureSourceAppIcon(for historyItem: HistoryItem) {
        sourceAppIconView.image = SourceAppIconProvider.icon(forBundleId: historyItem.sourceBundleId)
        sourceAppIconView.isHidden = false
        sourceAppIconView.toolTip = historyItem.sourceBundleId
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let table = hostTableView else { return }
        let location = convert(event.locationInWindow, from: nil)
        let row = table.row(at: location)
        guard row >= 0, row < table.historyListItems.count else { return }
        // Finder-like: right-click selects the row first (U17).
        if table.selected != row {
            table.selectItem(row)
        }
        displayedRow = row
        let item = table.historyListItems[row]
        let kind: ItemKind
        if item.isPassword {
            kind = .password
        } else if item.getColor() != nil {
            kind = .color
        } else if item.getImage() != nil {
            kind = .image
        } else {
            kind = .text
        }
        let model = ContextMenuBuilder.build(
            kind: kind,
            isPassword: item.isPassword,
            isFavorite: item.isFavorite,
            selectionCount: 1,
            sourceAppName: item.sourceBundleId?.split(separator: ".").last.map(String.init)
        )
        let menu = NSMenu(title: "Item")
        for (index, block) in model.sections.enumerated() {
            if index > 0 { menu.addItem(.separator()) }
            for entry in block.items where entry.isEnabled || entry.commandID == .toggleFavorite {
                let title: String
                switch entry.titleKey {
                case "unfavorite": title = L10n.contextRemoveFromFavorites
                case "copyLogin": title = L10n.contextCopyLogin
                case "copyPassword": title = L10n.contextCopyPassword
                case "copyURL": title = L10n.contextCopyURL
                case "openURL": title = L10n.contextOpenURL
                case "editPassword": title = L10n.contextEdit
                case "removeFromPasswords": title = L10n.contextRemoveFromPasswords
                case "saveToPasswords": title = L10n.contextSaveToPasswords
                case "filterByApp":
                    let name = item.sourceBundleId?.split(separator: ".").last.map(String.init) ?? ""
                    title = "\(L10n.commandTitle(for: "command.filterApp")) «\(name)»"
                default:
                    if let id = entry.commandID {
                        title = PanelCommandRegistry.command(id: id).title
                    } else {
                        title = L10n.commandTitle(for: entry.titleKey)
                    }
                }
                let menuItem = NSMenuItem(title: title, action: selector(for: entry), keyEquivalent: "")
                menuItem.isEnabled = entry.isEnabled || entry.commandID == .toggleFavorite
                if let symbol = NSImage(systemSymbolName: entry.symbolName, accessibilityDescription: nil) {
                    menuItem.image = symbol
                }
                if let id = entry.commandID,
                   let chord = PanelCommandRegistry.command(id: id).bindings.first?.chord {
                    menuItem.toolTip = chord.displayString
                }
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    private func selector(for entry: ContextMenuItem) -> Selector {
        switch entry.titleKey {
        case "copyLogin": return #selector(contextCopyPasswordLogin(_:))
        case "copyURL": return #selector(contextCopyPasswordURL(_:))
        case "openURL": return #selector(contextOpenPasswordURL(_:))
        case "copyPassword": return #selector(contextCopyPasswordValue(_:))
        case "editPassword": return #selector(contextEditPasswordEntry(_:))
        case "removeFromPasswords": return #selector(contextRemoveFromPasswords(_:))
        case "saveToPasswords": return #selector(contextSaveToPasswords(_:))
        case "unfavorite": return #selector(contextToggleFavorite(_:))
        default: break
        }
        switch entry.commandID {
        case .toggleFavorite: return #selector(contextToggleFavorite(_:))
        case .delete: return #selector(contextDeleteItem(_:))
        default: return #selector(contextToggleFavorite(_:))
        }
    }
    
    @objc private func contextToggleFavorite(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, toggleFavoriteAt: displayedRow)
    }
    
    @objc private func contextSaveToPasswords(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, saveToPasswordsAt: displayedRow)
    }
    
    @objc private func contextRemoveFromPasswords(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, removeFromPasswordsAt: displayedRow)
    }
    
    @objc private func contextEditPasswordEntry(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, editPasswordEntryAt: displayedRow)
    }
    
    @objc private func contextCopyPasswordLogin(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, copyPasswordLoginAt: displayedRow)
    }
    
    @objc private func contextCopyPasswordValue(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, copyPasswordValueAt: displayedRow)
    }
    
    @objc private func contextCopyPasswordURL(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, copyPasswordURLAt: displayedRow)
    }
    
    @objc private func contextOpenPasswordURL(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, openPasswordURLAt: displayedRow)
    }
    
    @objc private func contextDeleteItem(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, deleteItemAt: displayedRow)
    }
}

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
    
    static var contentViewInsets: NSEdgeInsets { HistoryListTheme.metrics.cardInsets }
    static var sourceAppIconSize: CGFloat { HistoryListTheme.metrics.sourceAppIconSize }
    static var sourceAppIconTrailingInset: CGFloat { HistoryListTheme.metrics.sourceAppIconTrailingInset }
    static var sourceAppIconSpacing: CGFloat { HistoryListTheme.metrics.sourceAppIconSpacing }
    
    class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("HistoryItemBaseCellView")
    }
    
    var contentView: HistoryItemContentView!
    var shortcutTextView: HistoryItemCellTextView!
    var itemTextView: HistoryItemCellTextView!
    var sourceAppIconView: NSImageView!
    
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
        layer?.backgroundColor = HistoryListTheme.colors.rowOuterFill(
            isSelected: isRowSelected,
            isHovered: isRowHovered
        ).cgColor
        
        contentView?.isRowSelected = isRowSelected
        updateShortcutAppearance()
    }
    
    private func updateShortcutAppearance() {
        guard let index = shortcutRowIndex, index < 10 else { return }
        
        if isRowSelected {
            shortcutTextView.backgroundColor = HistoryListTheme.colors.shortcutBackgroundSelected
            shortcutTextView.attributedText = NSAttributedString(
                string: "⌘ + \(index)",
                attributes: Self.shortcutAttributes(selected: true)
            )
        } else {
            shortcutTextView.backgroundColor = HistoryListTheme.colors.accent
            shortcutTextView.attributedText = NSAttributedString(
                string: "⌘ + \(index)",
                attributes: Self.shortcutAttributes(selected: false)
            )
        }
    }
    
    private static func shortcutAttributes(selected: Bool) -> [NSAttributedString.Key: Any] {
        [
            .font: HistoryListTheme.typography.body,
            .foregroundColor: selected
                ? HistoryListTheme.colors.shortcutForegroundSelected
                : HistoryListTheme.colors.shortcutForegroundNormal,
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
        contentView = HistoryItemContentView(frame: .zero)
        addSubview(contentView)
        itemTextView = HistoryItemCellTextView(frame: .zero)
        contentView.addSubview(itemTextView)
        shortcutTextView = HistoryItemCellTextView(frame: .zero)
        contentView.addSubview(shortcutTextView)
        
        wantsLayer = true
        layer?.cornerRadius = HistoryListTheme.metrics.rowOuterRadius
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
        sourceAppIconView = NSImageView(frame: .zero)
        sourceAppIconView.translatesAutoresizingMaskIntoConstraints = false
        sourceAppIconView.imageScaling = .scaleProportionallyDown
        sourceAppIconView.wantsLayer = true
        sourceAppIconView.layer?.cornerRadius = HistoryListTheme.metrics.sourceAppIconCornerRadius
        sourceAppIconView.layer?.backgroundColor = HistoryListTheme.colors.sourceIconBackdrop.cgColor
        sourceAppIconView.layer?.masksToBounds = true
        addSubview(sourceAppIconView)
        
        sourceAppIconView.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -Self.sourceAppIconTrailingInset
        ).isActive = true
        sourceAppIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sourceAppIconView.widthAnchor.constraint(equalToConstant: Self.sourceAppIconSize).isActive = true
        sourceAppIconView.heightAnchor.constraint(equalToConstant: Self.sourceAppIconSize).isActive = true
    }
    
    func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = HistoryListTheme.metrics.cardRadius
        
        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: Self.contentViewInsets.left))
        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: Self.contentViewInsets.top))
        addConstraint(NSLayoutConstraint(item: sourceAppIconView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: Self.sourceAppIconSpacing))
        addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: Self.contentViewInsets.bottom))
    }
    
    func setupShortcutTextView() {
        shortcutTextView.translatesAutoresizingMaskIntoConstraints = false
        shortcutTextView.wantsLayer = true
        shortcutTextView.isSelectable = false
        shortcutTextView.textContainer?.lineFragmentPadding = 0
        shortcutTextView.alignment = .right
        shortcutTextView.textContainerInset = HistoryListTheme.metrics.shortcutTextInset
        shortcutTextView.layer?.cornerRadius = HistoryListTheme.metrics.shortcutCornerRadius
        shortcutTextView.layer?.maskedCorners = .layerMinXMaxYCorner
        shortcutTextView.isHorizontallyResizable = false
        shortcutTextView.isVerticallyResizable = false
        shortcutTextView.backgroundColor = HistoryListTheme.colors.accent
        shortcutTextView.layer?.zPosition = 1
        
        contentView.addConstraint(NSLayoutConstraint(item: shortcutTextView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: shortcutTextView, attribute: .trailing, multiplier: 1, constant: 0))
        shortcutTextView.widthAnchor.constraint(equalToConstant: 0, withIdentifier: "width")?.isActive = true
        shortcutTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func getShortcutTextViewSize() -> NSSize {
        let bRect = shortcutTextView.attributedString().getSingleLineSize()
        let inset = shortcutTextView.textContainerInset
        return NSSize(
            width: bRect.width + shortcutTextView.textContainer!.lineFragmentPadding + inset.width * 2,
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
        sourceAppIconView.toolTip = historyItem.sourceBundleId
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let table = hostTableView else { return }
        let location = convert(event.locationInWindow, from: nil)
        let row = table.row(at: location)
        guard row >= 0, row < table.historyListItems.count else { return }
        displayedRow = row
        let item = table.historyListItems[row]
        let favoriteTitle = item.isFavorite ? "Remove from Favorites" : "Add to Favorites"
        let favoriteItem = NSMenuItem(title: favoriteTitle, action: #selector(contextToggleFavorite(_:)), keyEquivalent: "")
        let deleteItem = NSMenuItem(
            title: "Delete",
            action: #selector(contextDeleteItem(_:)),
            keyEquivalent: Constants.statusItemMenu.deleteKeyEquivalent
        )
        deleteItem.keyEquivalentModifierMask = .control
        
        var menuItems: [NSMenuItem] = [favoriteItem]
        if item.isPassword {
            menuItems.append(NSMenuItem(title: "Edit Comment…", action: #selector(contextEditPasswordComment(_:)), keyEquivalent: ""))
            menuItems.append(NSMenuItem(title: "Remove from Passwords", action: #selector(contextRemoveFromPasswords(_:)), keyEquivalent: ""))
        } else {
            menuItems.append(NSMenuItem(title: "Save to Passwords…", action: #selector(contextSaveToPasswords(_:)), keyEquivalent: ""))
        }
        menuItems.append(NSMenuItem.separator())
        menuItems.append(deleteItem)
        
        let menu = NSMenu(title: "Item")
        menuItems.forEach { menu.addItem($0) }
        menu.items.forEach { $0.target = self }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
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
    
    @objc private func contextEditPasswordComment(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, editPasswordCommentAt: displayedRow)
    }
    
    @objc private func contextDeleteItem(_ sender: NSMenuItem) {
        guard let table = hostTableView, displayedRow >= 0 else { return }
        table.historyDelegate?.historyTableView(table, deleteItemAt: displayedRow)
    }
}

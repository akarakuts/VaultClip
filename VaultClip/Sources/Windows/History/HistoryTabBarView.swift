//
//  HistoryTabBarView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

struct HistoryTabDefinition {
    let mode: HistoryListMode
    let title: String
    let iconName: String
    let fallbackGlyph: String
}

protocol HistoryTabBarViewDelegate: AnyObject {
    func historyTabBarView(_ tabBar: HistoryTabBarView, didSelect mode: HistoryListMode)
}

/// macOS-style tabs: selected segment uses card background and connects to the list below.
final class HistoryTabBarView: NSView {
    
    weak var delegate: HistoryTabBarViewDelegate?
    
    private var definitions: [HistoryTabDefinition] = []
    private var tabItems: [HistoryTabItemView] = []
    private let separatorView = NSView()
    private var selectedIndex = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        separatorView.wantsLayer = true
        separatorView.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor
        addSubview(separatorView)
    }
    
    func configure(with definitions: [HistoryTabDefinition]) {
        tabItems.forEach { $0.removeFromSuperview() }
        tabItems = definitions.enumerated().map { index, definition in
            let item = HistoryTabItemView(definition: definition)
            item.tag = index
            item.target = self
            item.action = #selector(tabClicked(_:))
            addSubview(item)
            return item
        }
        self.definitions = definitions
        needsLayout = true
        selectTab(at: selectedIndex, notifyDelegate: false)
    }
    
    func selectTab(at index: Int) {
        selectTab(at: index, notifyDelegate: false)
    }
    
    private func selectTab(at index: Int, notifyDelegate: Bool) {
        guard index >= 0, index < tabItems.count else { return }
        selectedIndex = index
        for (i, item) in tabItems.enumerated() {
            item.isSelected = i == index
        }
        if notifyDelegate, let mode = definitions[safe: index]?.mode {
            delegate?.historyTabBarView(self, didSelect: mode)
        }
    }
    
    @objc private func tabClicked(_ sender: HistoryTabItemView) {
        selectTab(at: sender.tag, notifyDelegate: true)
    }
    
    override func layout() {
        super.layout()
        guard !tabItems.isEmpty else { return }
        
        let separatorHeight: CGFloat = 1
        separatorView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: separatorHeight)
        
        let minWidths = tabItems.map { $0.preferredMinWidth }
        let totalMin = minWidths.reduce(0, +)
        let tabHeights = bounds.height - separatorHeight
        var x: CGFloat = 0
        
        if totalMin <= bounds.width {
            let extra = bounds.width - totalMin
            let extraPerTab = extra / CGFloat(tabItems.count)
            for (index, item) in tabItems.enumerated() {
                let width = index == tabItems.count - 1
                    ? bounds.width - x
                    : floor(minWidths[index] + extraPerTab)
                item.frame = NSRect(x: x, y: separatorHeight, width: width, height: tabHeights)
                x += width
            }
        } else {
            let scale = bounds.width / totalMin
            for (index, item) in tabItems.enumerated() {
                let width = index == tabItems.count - 1
                    ? bounds.width - x
                    : floor(minWidths[index] * scale)
                item.frame = NSRect(x: x, y: separatorHeight, width: width, height: tabHeights)
                x += width
            }
        }
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: HistoryListTheme.metrics.tabBarHeight)
    }
}

// MARK: - Tab item

private final class HistoryTabItemView: NSControl {
    
    private let definition: HistoryTabDefinition
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let backgroundLayer = CALayer()
    
    var isSelected = false {
        didSet { updateAppearance() }
    }
    
    private var isHovered = false
    
    init(definition: HistoryTabDefinition) {
        self.definition = definition
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.masksToBounds = false
        
        backgroundLayer.masksToBounds = true
        backgroundLayer.cornerRadius = HistoryListTheme.metrics.tabCornerRadius
        backgroundLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer?.addSublayer(backgroundLayer)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        addSubview(iconView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = definition.title
        titleLabel.font = NSFont.systemFont(ofSize: HistoryListTheme.typography.tabSize, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HistoryListTheme.metrics.tabContentInset),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            iconView.widthAnchor.constraint(equalToConstant: HistoryListTheme.metrics.tabIconSize),
            iconView.heightAnchor.constraint(equalToConstant: HistoryListTheme.metrics.tabIconSize),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: HistoryListTheme.metrics.tabIconSpacing),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -HistoryListTheme.metrics.tabContentInset),
        ])
        
        updateIcon()
        updateAppearance()
        installTracking()
    }
    
    override func layout() {
        super.layout()
        backgroundLayer.frame = bounds
    }
    
    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }
    
    private func installTracking() {
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
        trackingAreas.forEach { removeTrackingArea($0) }
        installTracking()
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        updateAppearance()
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        updateAppearance()
    }
    
    private func updateIcon() {
        if #available(macOS 11.0, *) {
            if let image = NSImage(systemSymbolName: definition.iconName, accessibilityDescription: definition.title) {
                image.isTemplate = true
                iconView.image = image
                return
            }
        }
        titleLabel.stringValue = "\(definition.fallbackGlyph) \(definition.title)"
        iconView.isHidden = true
    }
    
    var preferredMinWidth: CGFloat {
        let titleWidth = (titleLabel.stringValue as NSString).size(withAttributes: [.font: titleLabel.font!]).width
        let chrome = HistoryListTheme.metrics.tabContentInset * 2
            + HistoryListTheme.metrics.tabIconSize
            + HistoryListTheme.metrics.tabIconSpacing
        return ceil(titleWidth + chrome)
    }
    
    private func updateAppearance() {
        if isSelected {
            backgroundLayer.backgroundColor = (NSColor(named: NSColor.Name("TextBackgroundColor")) ?? .controlBackgroundColor).cgColor
            backgroundLayer.borderWidth = 1
            backgroundLayer.borderColor = NSColor.separatorColor.withAlphaComponent(0.45).cgColor
            titleLabel.textColor = .labelColor
            iconView.contentTintColor = HistoryListTheme.colors.accent
        } else {
            backgroundLayer.backgroundColor = isHovered
                ? NSColor.separatorColor.withAlphaComponent(0.12).cgColor
                : NSColor.clear.cgColor
            backgroundLayer.borderWidth = 0
            titleLabel.textColor = .secondaryLabelColor
            iconView.contentTintColor = .secondaryLabelColor
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

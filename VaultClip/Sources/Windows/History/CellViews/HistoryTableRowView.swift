//
// HistoryTableRowView — rounded inset selection/hover background for history rows (U11).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class HistoryTableRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("HistoryTableRowView")

    private var keyObservers: [NSObjectProtocol] = []

    var isHovered = false {
        didSet { if isHovered != oldValue { needsDisplay = true } }
    }

    override var isSelected: Bool {
        didSet {
            subviews.compactMap { $0 as? HistoryRowView }.forEach { $0.setRowSelected(isSelected) }
        }
    }

    /// Focus usually sits in the search field, so the table is never first responder;
    /// follow the panel's key state instead (Spotlight-style accent selection).
    override var isEmphasized: Bool {
        get { window?.isKeyWindow ?? super.isEmphasized }
        set { super.isEmphasized = newValue }
    }

    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        (subview as? HistoryRowView)?.setRowSelected(isSelected)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        keyObservers.forEach(NotificationCenter.default.removeObserver)
        keyObservers.removeAll()
        guard let window else { return }
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            keyObservers.append(NotificationCenter.default.addObserver(
                forName: name, object: window, queue: .main
            ) { [weak self] _ in
                self?.refreshEmphasis()
            })
        }
    }

    deinit {
        keyObservers.forEach(NotificationCenter.default.removeObserver)
    }

    private func refreshEmphasis() {
        needsDisplay = true
        let style = interiorBackgroundStyle
        subviews.compactMap { $0 as? NSTableCellView }.forEach { $0.backgroundStyle = style }
    }

    private var rowRect: NSRect {
        bounds.insetBy(dx: 2, dy: 1)
    }

    override func drawSelection(in dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: rowRect, xRadius: 6, yRadius: 6)
        // The system unemphasized gray vanishes on the sidebar material; use a visible label tint.
        let color: NSColor = isEmphasized
            ? .selectedContentBackgroundColor
            : NSColor.labelColor.withAlphaComponent(0.14)
        color.setFill()
        path.fill()
    }

    override func drawBackground(in dirtyRect: NSRect) {
        guard isHovered, !isSelected else { return }
        let path = NSBezierPath(roundedRect: rowRect, xRadius: 6, yRadius: 6)
        NSColor.labelColor.withAlphaComponent(0.06).setFill()
        path.fill()
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        isSelected && isEmphasized ? .emphasized : .normal
    }
}

//
// PanelToastView — single transient message above the footer, optional action (U09/U18).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class PanelToastView: NSVisualEffectView {
    private let label = NSTextField(labelWithString: "")
    private let button = NSButton(title: "", target: nil, action: nil)
    private var action: (() -> Void)?
    private var hideWork: DispatchWorkItem?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true
        isHidden = true

        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.bezelStyle = .inline
        button.contentTintColor = .controlAccentColor
        button.target = self
        button.action = #selector(buttonTapped)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = NSStackView(views: [label, button])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        syncPanelOverlayChrome()
    }

    func syncPanelOverlayChrome() {
        let style = PanelChromeStyleResolver.currentStyle(kind: .floating)
        material = style.usesSolidBackground ? .contentBackground : style.toastMaterial
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(message: String, actionTitle: String?, duration: TimeInterval, action: (() -> Void)?) {
        hideWork?.cancel()
        label.stringValue = message
        button.title = actionTitle ?? ""
        button.isHidden = actionTitle == nil
        self.action = action
        superview?.addSubview(self, positioned: .above, relativeTo: nil)
        alphaValue = 1
        isHidden = false
        NSAccessibility.post(
            element: self,
            notification: .announcementRequested,
            userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high.rawValue]
        )
        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    func dismiss() {
        hideWork?.cancel()
        hideWork = nil
        action = nil
        isHidden = true
    }

    /// Pass clicks through the chrome so the toast never steals list selection; only Undo is hittable.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, let hit = super.hitTest(point) else { return nil }
        if hit === button || hit.isDescendant(of: button) { return hit }
        return nil
    }

    @objc private func buttonTapped() {
        let run = action
        dismiss()
        run?()
    }
}

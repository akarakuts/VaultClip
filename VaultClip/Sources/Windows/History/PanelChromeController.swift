//
// PanelChromeController — NSVisualEffectView root chrome, contrast, motion (U06).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import QuartzCore

final class PanelChromeController {
    private weak var window: NSWindow?
    private weak var contentView: NSView?
    private var effectView: NSVisualEffectView?
    private var separator: NSView?
    private var accessibilityObserver: NSObjectProtocol?
    private var position: PanelPosition = .right

    func attach(to window: NSWindow, contentRoot: NSView) {
        self.window = window
        self.contentView = contentRoot
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear

        let effect = NSVisualEffectView(frame: contentRoot.bounds)
        effect.autoresizingMask = [.width, .height]
        effect.blendingMode = PanelTheme.visualEffectBlendingMode
        effect.state = PanelTheme.visualEffectState
        contentRoot.addSubview(effect, positioned: .below, relativeTo: nil)
        self.effectView = effect

        let line = NSView(frame: .zero)
        line.wantsLayer = true
        line.translatesAutoresizingMaskIntoConstraints = false
        contentRoot.addSubview(line)
        self.separator = line

        accessibilityObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyChrome(for: self?.position ?? .right)
        }
        applyChrome(for: position)
    }

    deinit {
        if let accessibilityObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(accessibilityObserver)
        }
    }

    func applyChrome(for position: PanelPosition) {
        self.position = position
        guard let window, let effectView, let contentView else { return }

        let floating = position.isFloating
        let kind: PanelTheme.PanelMaterialKind = floating ? .floating : .edge
        effectView.material = PanelTheme.visualEffectMaterial(for: kind)

        if PanelTheme.prefersSolidBackground {
            effectView.isHidden = true
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = PanelTheme.solidBackgroundColor.cgColor
        } else {
            effectView.isHidden = false
            contentView.layer?.backgroundColor = nil
        }

        let radius: CGFloat = floating ? PanelTheme.Radius.centerWindow : 0
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = radius
        window.contentView?.layer?.masksToBounds = radius > 0
        if floating {
            window.hasShadow = true
        } else {
            window.hasShadow = true
        }

        layoutSeparator(for: position, in: contentView)
        updateSeparatorAppearance()
    }

    func animateShow(fromEdge offset: CGFloat = PanelTheme.showSlideOffset, completion: (() -> Void)? = nil) {
        guard let window else { completion?(); return }
        let durations = PanelTheme.motionDurations()
        let end = window.frame
        var start = end
        switch position {
        case .left: start.origin.x -= offset
        case .right: start.origin.x += offset
        case .top: start.origin.y += offset
        case .bottom: start.origin.y -= offset
        default: break
        }
        window.alphaValue = 0
        window.setFrame(start, display: false)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = durations.show
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(end, display: true)
        }, completionHandler: completion)
    }

    func animateHide(completion: (() -> Void)? = nil) {
        guard let window else { completion?(); return }
        let durations = PanelTheme.motionDurations()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = durations.hide
            window.animator().alphaValue = 0
        }, completionHandler: completion)
    }

    private func layoutSeparator(for position: PanelPosition, in root: NSView) {
        guard let separator else { return }
        separator.removeFromSuperview()
        root.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(separator.constraints)
        let thickness: CGFloat = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 2 : 1
        switch position {
        case .left:
            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: root.topAnchor),
                separator.bottomAnchor.constraint(equalTo: root.bottomAnchor),
                separator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                separator.widthAnchor.constraint(equalToConstant: thickness)
            ])
            separator.isHidden = false
        case .right:
            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: root.topAnchor),
                separator.bottomAnchor.constraint(equalTo: root.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                separator.widthAnchor.constraint(equalToConstant: thickness)
            ])
            separator.isHidden = false
        case .top:
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: root.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: thickness)
            ])
            separator.isHidden = false
        case .bottom:
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                separator.topAnchor.constraint(equalTo: root.topAnchor),
                separator.heightAnchor.constraint(equalToConstant: thickness)
            ])
            separator.isHidden = false
        default:
            separator.isHidden = true
        }
    }

    private func updateSeparatorAppearance() {
        let contrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        separator?.layer?.backgroundColor = (contrast ? NSColor.labelColor : NSColor.separatorColor).cgColor
    }
}

extension PanelPosition {
    var isFloating: Bool {
        switch self {
        case .center, .fullScreen:
            return true
        case .left, .right, .top, .bottom:
            return false
        }
    }
}

//
// PanelLocalKeyMonitor — NSEvent local keyDown while the history panel is key (U04).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class PanelLocalKeyMonitor {
    private var monitor: Any?
    private let matcher: KeyChordMatcher
    var isActive: Bool { monitor != nil }

    /// Windows that count as “panel key” (panel + sheets/child overlays).
    var isPanelKeyWindow: ((NSWindow?) -> Bool)?
    var focusZone: () -> FocusZone = { .search }
    var routerContext: () -> PanelKeyRouterContext = { PanelKeyRouterContext() }
    var onRoute: ((PanelKeyRoute, NSEvent) -> Bool)?

    init(matcher: KeyChordMatcher = KeyChordMatcher()) {
        self.matcher = matcher
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isPanelKeyWindow?(event.window) ?? false else { return event }
        guard let chord = matcher.chord(from: event) else { return event }

        let zone = focusZone()
        let typed = event.charactersIgnoringModifiers
        let route = PanelKeyRouter.route(
            zone: zone,
            chord: chord,
            typed: typed,
            context: routerContext()
        )

        let consumed = onRoute?(route, event) ?? false
        return consumed ? nil : event
    }
}

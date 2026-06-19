//
// AppRouting — UI navigation surface decoupled from Controller singleton.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

/// Window and panel actions exposed to storyboard VCs and helpers.
protocol AppRouting: AnyObject {
    var welcomeWindowController: WelcomeWindowController { get }
    var helpWindowController: HelpWindowController { get }
    func togglePopover()
}

extension Controller: AppRouting {}

//
//  NSStoryboard+VaultClip.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

extension NSStoryboard {

    static func instantiateOrTerminate<T>(
        name: String = "Main",
        identifier: String,
        as type: T.Type = T.self,
        file: StaticString = #file,
        line: UInt = #line
    ) -> T {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(name), bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: identifier)
        let raw = storyboard.instantiateController(withIdentifier: sceneIdentifier)

        if let typed = raw as? T {
            return typed
        }

        let alert = NSAlert()
        alert.messageText = "\(Constants.branding.displayName) is corrupted"
        alert.informativeText = """
        Failed to load \(identifier) from storyboard "\(name)".
        Please reinstall the application.
        """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.runModal()

        NSApp.terminate(nil)
        // Unreachable, but the compiler still wants a value of T.
        // Use a dispatch trap rather than fatalError so the message above
        // is what the user actually sees.
        repeat { RunLoop.main.run(until: .distantFuture) } while true
    }
}

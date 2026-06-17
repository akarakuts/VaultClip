#!/usr/bin/env swift
// Clicks a VaultClip history-panel tab by index (0=History, 1=Favorites, 2=Passwords).
import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count >= 2,
      let tabIndex = Int(CommandLine.arguments[1]),
      (0...2).contains(tabIndex) else {
    fputs("usage: click-history-tab.swift <0|1|2>\n", stderr)
    exit(2)
}

let running = NSWorkspace.shared.runningApplications.first {
    $0.bundleIdentifier == "com.karakuts.VaultClip"
}
guard let app = running else {
    fputs("VaultClip is not running\n", stderr)
    exit(1)
}

let opts = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

var target: [String: Any]?
for w in list {
    guard let owner = w[kCGWindowOwnerName as String] as? String, owner == "VaultClip" else { continue }
    guard let layer = w[kCGWindowLayer as String] as? Int, layer >= 0, layer <= 25 else { continue }
    let bounds = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let width = bounds["Width"] ?? 0
    if width >= 300 {
        target = w
        break
    }
}
guard let window = target,
      let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
      let winX = bounds["X"], let winY = bounds["Y"],
      let winW = bounds["Width"], let winH = bounds["Height"] else {
    fputs("history window not found\n", stderr)
    exit(1)
}

// Layout mirrors HistoryListTheme.metrics (contentScale 0.855).
let scale: CGFloat = 0.855
let yFromTop = scale * (30 + 15 + 8 + 28 + 15 + 18)
let tabCenterX = (winW / 3) * (CGFloat(tabIndex) + 0.5)

// CGWindow bounds: origin top-left of primary display.
let clickX = winX + tabCenterX
let clickY = winY + yFromTop

app.activate(options: [.activateIgnoringOtherApps])
usleep(200_000)

func postClick(at point: CGPoint) {
    guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
          let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
        exit(1)
    }
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
}

postClick(at: CGPoint(x: clickX, y: clickY))
usleep(400_000)

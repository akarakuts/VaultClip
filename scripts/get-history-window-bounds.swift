#!/usr/bin/env swift
// Prints: windowId x y width height (Quartz coords, origin top-left).
import AppKit
import Foundation

let opts = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}
for w in list {
    guard let owner = w[kCGWindowOwnerName as String] as? String, owner == "VaultClip" else { continue }
    guard let layer = w[kCGWindowLayer as String] as? Int, layer >= 0, layer <= 25 else { continue }
    guard let wid = w[kCGWindowNumber as String] as? UInt32, wid > 0 else { continue }
    let b = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let width = b["Width"] ?? 0
    if width >= 300 {
        print(wid, b["X"] ?? 0, b["Y"] ?? 0, width, b["Height"] ?? 0)
        exit(0)
    }
}
exit(1)

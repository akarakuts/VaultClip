#!/usr/bin/env swift
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
    let bounds = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let width = bounds["Width"] ?? 0
    if width >= 300 {
        print(wid)
        exit(0)
    }
}
exit(1)

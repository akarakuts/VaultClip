#!/usr/bin/env swift
// Pastes a window PNG onto a full-screen wallpaper capture at Quartz screen coordinates.
import AppKit
import Foundation

guard CommandLine.arguments.count >= 8 else {
    fputs("usage: composite-wallpaper-shot.swift <wallpaper> <panel> <out> <x> <y> <w> <h>\n", stderr)
    exit(2)
}

let wallpaperPath = CommandLine.arguments[1]
let panelPath = CommandLine.arguments[2]
let outPath = CommandLine.arguments[3]
let winXPoints = CGFloat(Double(CommandLine.arguments[4])!)
let winYPoints = CGFloat(Double(CommandLine.arguments[5])!)
let winWPoints = CGFloat(Double(CommandLine.arguments[6])!)
let winHPoints = CGFloat(Double(CommandLine.arguments[7])!)

guard let wallpaper = NSImage(contentsOfFile: wallpaperPath),
      let panel = NSImage(contentsOfFile: panelPath),
      let wallRep = wallpaper.representations.first as? NSBitmapImageRep else {
    fputs("failed to load images\n", stderr)
    exit(1)
}

let screenPoints = NSScreen.main?.frame.width ?? wallpaper.size.width / 2
let scale = CGFloat(wallRep.pixelsWide) / screenPoints
let winX = winXPoints * scale
let winY = winYPoints * scale
let winW = winWPoints * scale
let winH = winHPoints * scale

let screenH = wallpaper.size.height
let target = NSImage(size: wallpaper.size)
target.lockFocus()
wallpaper.draw(
    at: .zero,
    from: NSRect(origin: .zero, size: wallpaper.size),
    operation: .copy,
    fraction: 1
)
let drawY = screenH - winY - winH
panel.draw(
    in: NSRect(x: winX, y: drawY, width: winW, height: winH),
    from: NSRect(origin: .zero, size: panel.size),
    operation: .sourceOver,
    fraction: 1
)
target.unlockFocus()

let pngProps: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.55]
guard let tiff = target.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: pngProps) else {
    fputs("failed to encode png\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))

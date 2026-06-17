#!/usr/bin/env swift
// Builds a full-screen wallpaper plate without the history panel (edge-fill right strip).
import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let source = root.appendingPathComponent("images/screenshot-history.png")
let out = root.appendingPathComponent("scripts/demo-assets/desktop-wallpaper.png")
let panelWidthPoints: CGFloat = 430

guard let image = NSImage(contentsOf: source),
      let rep = image.representations.first as? NSBitmapImageRep else {
    fputs("failed to load source wallpaper\n", stderr)
    exit(1)
}

let w = rep.pixelsWide
let h = rep.pixelsHigh
let screenPoints = NSScreen.main?.frame.width ?? CGFloat(w) / 2
let scale = CGFloat(w) / screenPoints
let panelPixels = Int((panelWidthPoints * scale).rounded())

guard let dest = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: w,
    pixelsHigh: h,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { exit(1) }

let fillStart = max(0, w - panelPixels)
let edgeX = max(0, fillStart - 1)

for y in 0..<h {
    for x in 0..<w {
        let sx = x < fillStart ? x : edgeX
        if let c = rep.colorAt(x: sx, y: y) {
            dest.setColor(c, atX: x, y: y)
        }
    }
}

try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let png = dest.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: out)

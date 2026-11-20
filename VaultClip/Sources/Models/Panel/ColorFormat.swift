//
// ColorFormat — HEX/RGB/HSL/P3 string helpers for color preview (U22).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

struct ColorComponents: Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
}

enum ColorFormat {
    static func hex(from c: ColorComponents) -> String {
        let r = Int((c.red * 255).rounded())
        let g = Int((c.green * 255).rounded())
        let b = Int((c.blue * 255).rounded())
        if c.alpha < 0.999 {
            let a = Int((c.alpha * 255).rounded())
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func rgb(from c: ColorComponents) -> String {
        let r = Int((c.red * 255).rounded())
        let g = Int((c.green * 255).rounded())
        let b = Int((c.blue * 255).rounded())
        if c.alpha < 0.999 {
            return String(format: "rgba(%d, %d, %d, %.2f)", r, g, b, Double(c.alpha))
        }
        return "rgb(\(r), \(g), \(b))"
    }

    static func hsl(from c: ColorComponents) -> String {
        let (h, s, l) = rgbToHsl(r: c.red, g: c.green, b: c.blue)
        let hDeg = Int((h * 360).rounded())
        let sPct = Int((s * 100).rounded())
        let lPct = Int((l * 100).rounded())
        if c.alpha < 0.999 {
            return String(format: "hsla(%d, %d%%, %d%%, %.2f)", hDeg, sPct, lPct, Double(c.alpha))
        }
        return "hsl(\(hDeg), \(sPct)%, \(lPct)%)"
    }

    static func displayP3(from c: ColorComponents) -> String {
        if c.alpha < 0.999 {
            return String(
                format: "color(display-p3 %.3f %.3f %.3f / %.2f)",
                Double(c.red), Double(c.green), Double(c.blue), Double(c.alpha)
            )
        }
        return String(
            format: "color(display-p3 %.3f %.3f %.3f)",
            Double(c.red), Double(c.green), Double(c.blue)
        )
    }

    private static func rgbToHsl(r: CGFloat, g: CGFloat, b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let maxV = max(r, g, b)
        let minV = min(r, g, b)
        let l = (maxV + minV) / 2
        guard maxV != minV else { return (0, 0, l) }
        let d = maxV - minV
        let s = l > 0.5 ? d / (2 - maxV - minV) : d / (maxV + minV)
        let h: CGFloat
        if maxV == r {
            h = (g - b) / d + (g < b ? 6 : 0)
        } else if maxV == g {
            h = (b - r) / d + 2
        } else {
            h = (r - g) / d + 4
        }
        return (h / 6, s, l)
    }
}

#!/usr/bin/env swift
// seed-demo-history.swift — fills VaultClip history with marketing demo data (encrypted on disk).

import AppKit
import Foundation

let bundleId = "com.karakuts.VaultClip"
let appSupport = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/\(bundleId)", isDirectory: true)
let historyRoot = appSupport.appendingPathComponent("history", isDirectory: true)
let orderURL = historyRoot.appendingPathComponent("order.xml")
let repoRoot = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let assetsRoot = repoRoot.appendingPathComponent("scripts/demo-assets", isDirectory: true)

struct DemoItem {
    let id: UUID
    let copiedAt: Date
    let sourceBundleId: String?
    let payloads: [String: Data]
    let isFavorite: Bool
    let isPassword: Bool
    let passwordComment: String
    let passwordLogin: String
}

func sanitizedFileName(for type: String) -> String {
    type
        .replacingOccurrences(of: "%", with: "%25")
        .replacingOccurrences(of: "/", with: "%2F")
        .replacingOccurrences(of: ":", with: "%3A")
}

/// Legacy plaintext payloads; VaultClip loads them and re-encrypts on the next save.
func writePlain(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

func writeMeta(_ string: String, to url: URL) throws {
    guard let data = string.data(using: .utf8) else { return }
    try writePlain(data, to: url)
}

func utf8(_ string: String) -> Data { Data(string.utf8) }

func makeGradientPNG(width: Int, height: Int) -> Data? {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
    guard let rep else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.36, blue: 0.82, alpha: 1),
        NSColor(calibratedRed: 0.55, green: 0.22, blue: 0.78, alpha: 1),
    ])!
    gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 35)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 28, weight: .semibold),
        .foregroundColor: NSColor.white,
    ]
    "VaultClip UI".draw(at: NSPoint(x: 28, y: height / 2 - 14), withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

func makeColorData(red: CGFloat, green: CGFloat, blue: CGFloat) -> Data? {
    let color = NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("VaultClip.SeedColor"))
    pasteboard.clearContents()
    pasteboard.writeObjects([color])
    return pasteboard.data(forType: .color)
}

func makeRTF(_ string: String) -> Data? {
    let attr = NSAttributedString(
        string: string,
        attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor,
        ]
    )
    return try? attr.data(
        from: NSRange(location: 0, length: attr.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
}

func ensureAssets() throws {
    try FileManager.default.createDirectory(at: assetsRoot, withIntermediateDirectories: true)
    let pngURL = assetsRoot.appendingPathComponent("gradient-preview.png")
    if !FileManager.default.fileExists(atPath: pngURL.path),
       let png = makeGradientPNG(width: 640, height: 400) {
        try png.write(to: pngURL)
    }
    let notesURL = assetsRoot.appendingPathComponent("release-notes.md")
    if !FileManager.default.fileExists(atPath: notesURL.path) {
        try """
        # VaultClip 1.1.10

        - Encrypted clipboard history on disk
        - Favorites and Passwords tabs
        - Source app icons on each row
        """.write(to: notesURL, atomically: true, encoding: .utf8)
    }
    let pdfURL = assetsRoot.appendingPathComponent("invoice-q2.pdf")
    if !FileManager.default.fileExists(atPath: pdfURL.path) {
        let pdf = """
        %PDF-1.4
        1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
        2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
        3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 420 280]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
        4 0 obj<</Length 58>>stream
        BT /F1 18 Tf 48 210 Td (Invoice #VC-2048) Tj 0 -28 Td (Amount: 12 450 RUB) Tj ET
        endstream endobj
        5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
        xref
        0 6
        0000000000 65535 f
        0000000009 00000 n
        0000000058 00000 n
        0000000115 00000 n
        0000000260 00000 n
        0000000370 00000 n
        trailer<</Size 6/Root 1 0 R>>
        startxref
        447
        %%EOF
        """.data(using: .utf8)!
        try pdf.write(to: pdfURL)
    }
}

func buildDemoItems() throws -> [DemoItem] {
    try ensureAssets()
    let now = Date()
    func ago(_ minutes: Int) -> Date { now.addingTimeInterval(TimeInterval(-minutes * 60)) }

    let pngURL = assetsRoot.appendingPathComponent("gradient-preview.png")
    let notesURL = assetsRoot.appendingPathComponent("release-notes.md")
    let pdfURL = assetsRoot.appendingPathComponent("invoice-q2.pdf")
    let pngData = try Data(contentsOf: pngURL)
    let tiffData = NSBitmapImageRep(data: pngData)?.representation(using: .tiff, properties: [:])

    return [
        DemoItem(
            id: UUID(),
            copiedAt: ago(4),
            sourceBundleId: "com.apple.dt.Xcode",
            payloads: [
                "public.utf8-plain-text": utf8("""
                func syncHistoryPanel() {
                    alignHistoryListToScrollView()
                    historyListView.reloadData()
                }
                """),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(11),
            sourceBundleId: "com.apple.Safari",
            payloads: [
                "public.utf8-plain-text": utf8("https://github.com/akarakuts/VaultClip"),
                "public.url": utf8("https://github.com/akarakuts/VaultClip"),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(18),
            sourceBundleId: "com.apple.TextEdit",
            payloads: [
                "public.html": utf8("""
                <p><b>Meeting notes</b> — product sync</p>
                <ul><li>Ship encrypted history</li><li>Polish tab layout</li></ul>
                """),
                "public.utf8-plain-text": utf8("Meeting notes — product sync"),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(26),
            sourceBundleId: "com.apple.systempreferences",
            payloads: [
                "NSColorPboardType": makeColorData(red: 0.18, green: 0.52, blue: 0.96) ?? Data(),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(33),
            sourceBundleId: "com.apple.Preview",
            payloads: [
                "public.tiff": tiffData ?? pngData,
                "public.png": pngData,
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(41),
            sourceBundleId: "com.apple.finder",
            payloads: [
                "public.file-url": notesURL.dataRepresentation,
                "public.utf8-plain-text": utf8(notesURL.path),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(49),
            sourceBundleId: "com.apple.Preview",
            payloads: [
                "com.adobe.pdf": try Data(contentsOf: pdfURL),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(57),
            sourceBundleId: "com.apple.Notes",
            payloads: [
                "public.utf8-plain-text": utf8("VaultClip — local clipboard history with AES encryption and password-manager filtering."),
            ],
            isFavorite: false, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(70),
            sourceBundleId: "com.apple.dt.Xcode",
            payloads: [
                "public.utf8-plain-text": utf8("""
                docker compose up -d postgres redis
                export DATABASE_URL=postgres://vault@localhost:5432/clip
                """),
            ],
            isFavorite: true, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(82),
            sourceBundleId: "com.apple.Terminal",
            payloads: [
                "public.utf8-plain-text": utf8("ssh deploy@vaultclip.example -p 2222 -i ~/.ssh/vaultclip_ed25519"),
            ],
            isFavorite: true, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(95),
            sourceBundleId: "com.apple.Safari",
            payloads: [
                "public.utf8-plain-text": utf8("https://developer.apple.com/documentation/appkit/nspasteboard"),
                "public.url": utf8("https://developer.apple.com/documentation/appkit/nspasteboard"),
            ],
            isFavorite: true, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(108),
            sourceBundleId: "com.apple.TextEdit",
            payloads: [
                "public.rtf": makeRTF("License — VaultClip Pro (team bundle)\nSeats: 25") ?? Data(),
                "public.utf8-plain-text": utf8("License — VaultClip Pro (team bundle)"),
            ],
            isFavorite: true, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(121),
            sourceBundleId: "com.apple.Preview",
            payloads: [
                "public.tiff": tiffData ?? pngData,
            ],
            isFavorite: true, isPassword: false, passwordComment: "", passwordLogin: ""
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(140),
            sourceBundleId: "com.apple.Safari",
            payloads: ["public.utf8-plain-text": utf8("ghp_demo_VcL1p9xK2mN8qR4sT7uW0yZ")],
            isFavorite: false, isPassword: true,
            passwordComment: "GitHub — personal access token",
            passwordLogin: "akarakuts"
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(155),
            sourceBundleId: "com.apple.Safari",
            payloads: ["public.utf8-plain-text": utf8("AKIA-DEMO-VC9X2K4M8P1Q")],
            isFavorite: false, isPassword: true,
            passwordComment: "AWS IAM — deploy user",
            passwordLogin: "vaultclip-deploy"
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(170),
            sourceBundleId: "com.apple.systempreferences",
            payloads: ["public.utf8-plain-text": utf8("Nebula-5G-Studio")],
            isFavorite: false, isPassword: true,
            passwordComment: "Home Wi‑Fi",
            passwordLogin: "Nebula-5G-Studio"
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(185),
            sourceBundleId: "com.apple.Terminal",
            payloads: ["public.utf8-plain-text": utf8("P@ssw0rd!demo_pg_2026")],
            isFavorite: false, isPassword: true,
            passwordComment: "PostgreSQL — staging",
            passwordLogin: "vaultclip_app"
        ),
        DemoItem(
            id: UUID(),
            copiedAt: ago(200),
            sourceBundleId: "com.apple.Notes",
            payloads: ["public.utf8-plain-text": utf8("vc_live_sk_demo_51Rx8K2mN9pQ4sT7u")],
            isFavorite: false, isPassword: true,
            passwordComment: "Stripe — test secret key",
            passwordLogin: "acct_demo_01H8VC"
        ),
    ]
}

func writeItem(_ item: DemoItem) throws {
    let dir = historyRoot.appendingPathComponent(item.id.uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try writeMeta(String(item.copiedAt.timeIntervalSince1970), to: dir.appendingPathComponent("copiedAt"))
    if let bundle = item.sourceBundleId {
        try writeMeta(bundle, to: dir.appendingPathComponent("sourceBundleId"))
    }
    if item.isFavorite {
        try writeMeta("1", to: dir.appendingPathComponent("favorite"))
    }
    if item.isPassword {
        try writeMeta("1", to: dir.appendingPathComponent("password"))
        if !item.passwordComment.isEmpty {
            try writeMeta(item.passwordComment, to: dir.appendingPathComponent("passwordComment"))
        }
        if !item.passwordLogin.isEmpty {
            try writeMeta(item.passwordLogin, to: dir.appendingPathComponent("passwordLogin"))
        }
    }
    for (type, data) in item.payloads where !data.isEmpty {
        let file = dir.appendingPathComponent(sanitizedFileName(for: type))
        try writePlain(data, to: file)
    }
}

do {
    if FileManager.default.fileExists(atPath: historyRoot.path) {
        try FileManager.default.removeItem(at: historyRoot)
    }
    try FileManager.default.createDirectory(at: historyRoot, withIntermediateDirectories: true)
    let items = try buildDemoItems()
    for item in items {
        try writeItem(item)
    }
    let order = items.map { $0.id.uuidString } as NSArray
    let plist = try PropertyListSerialization.data(fromPropertyList: order, format: .xml, options: 0)
    try writePlain(plist, to: orderURL)
    fputs("Seeded \(items.count) demo items.\n", stderr)
} catch {
    fputs("seed-demo-history failed: \(error)\n", stderr)
    exit(1)
}

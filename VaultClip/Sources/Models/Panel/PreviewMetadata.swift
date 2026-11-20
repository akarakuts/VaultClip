//
// PreviewMetadata — formatted metadata block for embedded preview (U22).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct PreviewMetadataModel: Equatable {
    var appName: String
    var copiedAtText: String
    var lastUsedAtText: String
    var sizeText: String
    var typeIdentifiers: [String]
}

enum PreviewMetadataFormatter {
    static func format(
        appName: String?,
        bundleId: String?,
        copiedAt: Date,
        lastUsedAt: Date,
        byteCount: Int,
        typeIdentifiers: [String],
        locale: Locale,
        now: Date = Date()
    ) -> PreviewMetadataModel {
        let name = appName?.isEmpty == false
            ? appName!
            : (bundleId?.components(separatedBy: ".").last ?? "—")
        let relative = RelativeDateTimeFormatter()
        relative.locale = locale
        relative.unitsStyle = .abbreviated
        let byteFormatter = ByteCountFormatter()
        byteFormatter.countStyle = .file
        byteFormatter.allowedUnits = [.useKB, .useMB, .useBytes]
        return PreviewMetadataModel(
            appName: name,
            copiedAtText: relative.localizedString(for: copiedAt, relativeTo: now),
            lastUsedAtText: relative.localizedString(for: lastUsedAt, relativeTo: now),
            sizeText: byteFormatter.string(fromByteCount: Int64(byteCount)),
            typeIdentifiers: typeIdentifiers
        )
    }
}

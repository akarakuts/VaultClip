//
// RowPresentation — title/subtitle for compact history rows (U05).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

struct ItemSummary: Equatable {
    var title: String
    var charCount: Int
    var lineCount: Int
    var linkHost: String?
    var fileNames: [String]
    var imagePixelSize: CGSize?
    var imageFormat: String?
    var colorHex: String?
    var sourceBundleId: String?
    var copiedAt: Date
    var lastUsedAt: Date
    var kind: ItemKind
    var passwordComment: String?
    var pdfPageCount: Int?
    var isRichText: Bool
    /// Resolved app display name (Finder name); falls back to the bundle id tail.
    var sourceAppName: String?
}

struct RowPresentation: Equatable, Identifiable {
    var id: UUID
    var kind: ItemKind
    var title: String
    /// Joined `source · time · meta` for VoiceOver and tooltip.
    var subtitle: String
    var sourceName: String?
    var timeText: String
    var metaText: String?
    var accessibilityLabel: String
    var sourceBundleId: String?
}

enum PanelListRow: Equatable, Identifiable {
    case header(id: String, title: String, count: Int)
    case item(RowPresentation, shortcutNumber: Int?)

    var id: String {
        switch self {
        case .header(let id, _, _): return "h:\(id)"
        case .item(let row, _): return "i:\(row.id.uuidString)"
        }
    }
}

enum PanelEmptyKind: Equatable {
    case history
    case favorites
    case passwords
    case noResults(query: String)
}

struct PanelPresenterInput {
    var items: [ItemSummary]
    var itemIds: [UUID]
    var tab: HistoryListMode
    var searchQuery: String
    var selectedIds: Set<UUID>
    var groupByDay: Bool
    var now: Date
    var calendar: Calendar
    var locale: Locale
}

struct PanelPresenterOutput: Equatable {
    var rows: [PanelListRow]
    var selectedRowIndexes: IndexSet
    var totalCount: Int
    var visibleCount: Int
    var emptyKind: PanelEmptyKind?
}

enum RowPresentationBuilder {
    /// First line shorter than this may append a second line via " — ".
    private static let shortTitleLimit = 40

    static func title(for summary: ItemSummary, locale: Locale) -> String {
        switch summary.kind {
        case .password:
            let comment = summary.passwordComment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return comment.isEmpty ? L10n.rowKindPassword : comment
        case .link:
            if let host = summary.linkHost, !host.isEmpty { return host }
            return collapseFirstLine(summary.title)
        case .file(let count):
            guard let first = summary.fileNames.first else {
                return L10n.rowKindFile
            }
            if count <= 1 || summary.fileNames.count <= 1 { return first }
            return "\(first) · \(L10n.rowAndMore(count - 1))"
        case .image:
            if let size = summary.imagePixelSize {
                return "\(Int(size.width))×\(Int(size.height))"
            }
            return summary.imageFormat ?? L10n.rowKindImage
        case .pdf:
            if !summary.title.isEmpty { return collapseFirstLine(summary.title) }
            if let pages = summary.pdfPageCount {
                return L10n.rowPdfPages(pages)
            }
            return "PDF"
        case .color:
            return summary.colorHex ?? "#000000"
        case .richText, .text:
            return textTitle(from: summary.title)
        }
    }

    static func sourceName(for summary: ItemSummary) -> String? {
        if let name = summary.sourceAppName, !name.isEmpty { return name }
        if let bundle = summary.sourceBundleId, let name = bundle.split(separator: ".").last {
            return String(name)
        }
        return nil
    }

    static func subtitle(for summary: ItemSummary, locale: Locale, now: Date) -> String {
        var parts: [String] = []
        if let name = sourceName(for: summary) {
            parts.append(name)
        }
        parts.append(relativeTime(from: summary.lastUsedAt, to: now, locale: locale))
        if let meta = meta(for: summary, locale: locale) {
            parts.append(meta)
        }
        return parts.joined(separator: " · ")
    }

    static func presentation(id: UUID, summary: ItemSummary, locale: Locale, now: Date) -> RowPresentation {
        let title = title(for: summary, locale: locale)
        let source = sourceName(for: summary)
        let time = relativeTime(from: summary.lastUsedAt, to: now, locale: locale)
        let meta = meta(for: summary, locale: locale)
        let subtitle = subtitle(for: summary, locale: locale, now: now)
        // Never include password secrets in a11y labels.
        let a11y = summary.kind == .password ? title : "\(title). \(subtitle)"
        return RowPresentation(
            id: id,
            kind: summary.kind,
            title: title,
            subtitle: subtitle,
            sourceName: source,
            timeText: time,
            metaText: meta,
            accessibilityLabel: a11y,
            sourceBundleId: summary.sourceBundleId
        )
    }

    static func collapseFirstLine(_ text: String) -> String {
        let line = nonEmptyLines(from: text).first ?? ""
        if line.count <= 200 { return line }
        return String(line.prefix(200))
    }

    /// First non-empty line; if short, append second via " — " (still one visual row).
    static func textTitle(from text: String) -> String {
        let lines = nonEmptyLines(from: text)
        guard let first = lines.first else { return "" }
        let head = first.count <= 200 ? first : String(first.prefix(200))
        guard head.count < shortTitleLimit, lines.count >= 2 else { return head }
        let combined = "\(head) — \(lines[1])"
        if combined.count <= 200 { return combined }
        return String(combined.prefix(200))
    }

    private static func nonEmptyLines(from text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
    }

    private static func meta(for summary: ItemSummary, locale: Locale) -> String? {
        _ = locale
        switch summary.kind {
        case .link:
            return L10n.rowMetaLink
        case .file(let count):
            return L10n.rowMetaFile(count)
        case .image:
            return summary.imageFormat
        case .pdf:
            // Pages in the tail only when the title already shows a document name.
            if !summary.title.isEmpty, let pages = summary.pdfPageCount {
                return L10n.rowPdfPages(pages)
            }
            return nil
        case .richText:
            return "RTF"
        case .text:
            if summary.lineCount > 1 {
                return L10n.rowMetaLines(summary.lineCount)
            }
            if summary.charCount > 0 {
                let formatted = NumberFormatter.localizedString(
                    from: NSNumber(value: summary.charCount), number: .decimal
                )
                return L10n.rowMetaChars(formatted)
            }
            return nil
        default:
            return nil
        }
    }

    /// Compact age («5 мин», «2 ч», «3 дн.», then a short date) — never a signed offset.
    static func relativeTime(from date: Date, to now: Date, locale: Locale) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60:
            return L10n.relativeJustNow
        case ..<3600:
            return L10n.relativeMinutes(Int(seconds / 60))
        case ..<86_400:
            return L10n.relativeHours(Int(seconds / 3600))
        case ..<(7 * 86_400):
            return L10n.relativeDays(Int(seconds / 86_400))
        default:
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate("d MMM")
            return formatter.string(from: date)
        }
    }

    static func russianPlural(_ n: Int, one: String, few: String, many: String) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1, mod100 != 11 { return one }
        if (2...4).contains(mod10), !(12...14).contains(mod100) { return few }
        return many
    }
}

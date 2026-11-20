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
    var sourceAppName: String? = nil
}

struct RowPresentation: Equatable, Identifiable {
    var id: UUID
    var kind: ItemKind
    var title: String
    var subtitle: String
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
    static func title(for summary: ItemSummary, locale: Locale) -> String {
        switch summary.kind {
        case .password:
            let comment = summary.passwordComment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return comment.isEmpty ? localized("Password", "Пароль", locale: locale) : comment
        case .link:
            if let host = summary.linkHost, !host.isEmpty { return host }
            return collapseFirstLine(summary.title)
        case .file(let count):
            guard let first = summary.fileNames.first else {
                return localized("File", "Файл", locale: locale)
            }
            if count <= 1 || summary.fileNames.count <= 1 { return first }
            let more = count - 1
            let suffix = locale.language.languageCode?.identifier == "ru"
                ? "и ещё \(more)"
                : "and \(more) more"
            return "\(first) · \(suffix)"
        case .image:
            let format = summary.imageFormat ?? "PNG"
            if let size = summary.imagePixelSize {
                let w = Int(size.width)
                let h = Int(size.height)
                let prefix = localized("Image", "Изображение", locale: locale)
                return "\(prefix) \(format) · \(w)×\(h)"
            }
            return "\(localized("Image", "Изображение", locale: locale)) \(format)"
        case .pdf:
            if !summary.title.isEmpty { return collapseFirstLine(summary.title) }
            if let pages = summary.pdfPageCount {
                let label = locale.language.languageCode?.identifier == "ru"
                    ? "PDF · \(pages) стр."
                    : "PDF · \(pages) pages"
                return label
            }
            return "PDF"
        case .color:
            return summary.colorHex ?? "#000000"
        case .richText, .text:
            return collapseFirstLine(summary.title)
        }
    }

    static func subtitle(for summary: ItemSummary, locale: Locale, now: Date) -> String {
        var parts: [String] = []
        if let name = summary.sourceAppName, !name.isEmpty {
            parts.append(name)
        } else if let bundle = summary.sourceBundleId, let name = bundle.split(separator: ".").last {
            parts.append(String(name))
        }
        parts.append(relativeTime(from: summary.lastUsedAt, to: now, locale: locale))
        if let meta = meta(for: summary, locale: locale) {
            parts.append(meta)
        }
        return parts.joined(separator: " · ")
    }

    static func presentation(id: UUID, summary: ItemSummary, locale: Locale, now: Date) -> RowPresentation {
        let title = title(for: summary, locale: locale)
        let subtitle = subtitle(for: summary, locale: locale, now: now)
        // Never include password secrets in a11y labels.
        let a11y = summary.kind == .password ? title : "\(title). \(subtitle)"
        return RowPresentation(
            id: id,
            kind: summary.kind,
            title: title,
            subtitle: subtitle,
            accessibilityLabel: a11y,
            sourceBundleId: summary.sourceBundleId
        )
    }

    static func collapseFirstLine(_ text: String) -> String {
        let line = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty })
            .map { String($0) } ?? ""
        let collapsed = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        if collapsed.count <= 200 { return collapsed }
        return String(collapsed.prefix(200))
    }

    private static func meta(for summary: ItemSummary, locale: Locale) -> String? {
        switch summary.kind {
        case .link:
            return localized("link", "ссылка", locale: locale)
        case .file(let count):
            return locale.language.languageCode?.identifier == "ru"
                ? "\(count) \(russianPlural(count, one: "файл", few: "файла", many: "файлов"))"
                : (count == 1 ? "1 file" : "\(count) files")
        case .richText:
            return "RTF"
        case .text:
            if summary.lineCount > 1 {
                let n = summary.lineCount
                return locale.language.languageCode?.identifier == "ru"
                    ? "\(n) \(russianPlural(n, one: "строка", few: "строки", many: "строк"))"
                    : "\(n) lines"
            }
            if summary.charCount > 0 {
                let formatted = NumberFormatter.localizedString(from: NSNumber(value: summary.charCount), number: .decimal)
                return locale.language.languageCode?.identifier == "ru"
                    ? "\(formatted) симв."
                    : "\(formatted) chars"
            }
            return nil
        default:
            return nil
        }
    }

    /// Compact age («5 мин», «2 ч», «3 дн.», then a short date) — never a signed offset.
    static func relativeTime(from date: Date, to now: Date, locale: Locale) -> String {
        let ru = locale.language.languageCode?.identifier == "ru"
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60:
            return ru ? "только что" : "now"
        case ..<3600:
            let m = Int(seconds / 60)
            return ru ? "\(m) мин" : "\(m) min"
        case ..<86_400:
            let h = Int(seconds / 3600)
            return ru ? "\(h) ч" : "\(h) h"
        case ..<(7 * 86_400):
            let d = Int(seconds / 86_400)
            return ru ? "\(d) дн." : "\(d) d"
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

    private static func localized(_ en: String, _ ru: String, locale: Locale) -> String {
        locale.language.languageCode?.identifier == "ru" ? ru : en
    }
}

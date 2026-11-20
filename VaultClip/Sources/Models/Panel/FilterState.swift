//
// FilterState — type/app filters and search-token parsing (U13/U14).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum TypeFilter: String, CaseIterable, Equatable {
    case all
    case text
    case link
    case image
    case file
    case color

    func matches(_ kind: ItemKind) -> Bool {
        switch self {
        case .all: return true
        case .text: return kind == .text || kind == .richText
        case .link: return kind == .link
        case .image: return kind == .image
        case .file:
            if case .file = kind { return true }
            return kind == .pdf
        case .color: return kind == .color
        }
    }
}

struct FilterState: Equatable {
    var type: TypeFilter = .all
    var appQuery: String? = nil

    var isActive: Bool { type != .all || !(appQuery?.isEmpty ?? true) }

    func matches(kind: ItemKind, sourceBundleId: String?, appDisplayName: String?) -> Bool {
        guard type.matches(kind) else { return false }
        guard let appQuery, !appQuery.isEmpty else { return true }
        let q = appQuery.lowercased()
        if let bundle = sourceBundleId?.lowercased(), bundle.contains(q) || bundle.hasPrefix(q) {
            return true
        }
        if let name = appDisplayName?.lowercased(), name.hasPrefix(q) || name.contains(q) {
            return true
        }
        if sourceBundleId == nil, appDisplayName == nil, q == "unknown" || q == "неизвестный" {
            return true
        }
        return false
    }
}

struct SearchTokenParseResult: Equatable {
    var remainingQuery: String
    var filter: FilterState
}

enum SearchTokenParser {
    static func parse(_ raw: String, base: FilterState = FilterState()) -> SearchTokenParseResult {
        var filter = base
        var leftover: [String] = []
        let parts = tokenize(raw)
        for part in parts {
            if let type = parseTypeToken(part) {
                filter.type = type
                continue
            }
            if let app = parseAppToken(part) {
                filter.appQuery = app
                continue
            }
            leftover.append(part)
        }
        return SearchTokenParseResult(remainingQuery: leftover.joined(separator: " "), filter: filter)
    }

    private static func tokenize(_ raw: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false
        for ch in raw {
            if ch == "\"" {
                inQuotes.toggle()
                current.append(ch)
                continue
            }
            if ch.isWhitespace, !inQuotes {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                continue
            }
            current.append(ch)
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    private static func parseTypeToken(_ token: String) -> TypeFilter? {
        let lower = token.lowercased()
        let prefixes = ["type:", "тип:"]
        guard let prefix = prefixes.first(where: { lower.hasPrefix($0) }) else { return nil }
        let value = String(lower.dropFirst(prefix.count))
        switch value {
        case "text", "текст", "richtext": return .text
        case "link", "ссылка", "url": return .link
        case "image", "картинка", "изображение": return .image
        case "file", "файл", "pdf": return .file
        case "color", "цвет": return .color
        case "all", "все", "": return .all
        default: return nil // partial token stays in query
        }
    }

    private static func parseAppToken(_ token: String) -> String? {
        let lower = token.lowercased()
        let prefixes = ["app:", "прил:"]
        guard let prefix = prefixes.first(where: { lower.hasPrefix($0) }) else { return nil }
        var value = String(token.dropFirst(prefix.count))
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        return value.isEmpty ? nil : value
    }
}

struct AppFilterAggregation: Equatable {
    var bundleId: String?
    var displayName: String
    var count: Int
}

enum AppFilterAggregator {
    static func aggregate(
        items: [(bundleId: String?, displayName: String)]
    ) -> [AppFilterAggregation] {
        var map: [String: AppFilterAggregation] = [:]
        for item in items {
            let key = item.bundleId ?? "unknown"
            let name = item.displayName.isEmpty
                ? (item.bundleId == nil ? "Unknown Source" : item.bundleId!)
                : item.displayName
            var entry = map[key] ?? AppFilterAggregation(bundleId: item.bundleId, displayName: name, count: 0)
            entry.count += 1
            map[key] = entry
        }
        return map.values.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}

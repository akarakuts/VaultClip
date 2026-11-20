//
// SearchIndex — folded substring search off the main thread with ranked results (T22).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import Foundation

/// Lightweight snapshot taken on main; payload text is filled on the index queue.
struct SearchSource: Equatable {
    let fsId: UUID
    let isPassword: Bool
    let passwordComment: String
    let passwordLogin: String
    let passwordURL: String
    let types: [NSPasteboard.PasteboardType]
    let copiedAt: Date
    /// Plain/RTF/HTML/URL seed from still-unsaved payloads (avoids empty index before disk flush).
    let prefetchedText: String?

    init(item: HistoryItem) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        fsId = item.fsId
        isPassword = item.isPassword
        passwordComment = item.passwordComment
        passwordLogin = item.passwordLogin
        passwordURL = item.passwordURL
        types = item.types
        copiedAt = item.copiedAt
        if item.isPassword {
            prefetchedText = nil
        } else if let unsaved = item.unsavedData {
            prefetchedText = Self.prefetch(from: unsaved, types: item.types)
        } else {
            prefetchedText = nil
        }
    }

    private static func prefetch(
        from unsaved: [NSPasteboard.PasteboardType: Data],
        types: [NSPasteboard.PasteboardType]
    ) -> String? {
        let available = Set(types)
        for type in HistoryItem.plainTextPasteboardTypes where available.contains(type) {
            if let data = unsaved[type], let string = String(data: data, encoding: .utf8), !string.isEmpty {
                return String(string.prefix(20_000))
            }
        }
        if let rtf = unsaved[.rtf], let attr = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            return String(attr.string.prefix(20_000))
        }
        if let html = unsaved[.html], let raw = String(data: html, encoding: .utf8) {
            return String(HistoryItemText.stripHTMLTagsForSearch(raw).prefix(20_000))
        }
        if available.contains(.URL), let data = unsaved[.URL], let url = HistoryItem.parseUrl(from: data) {
            return url.absoluteString
        }
        if available.contains(.fileURL), let data = unsaved[.fileURL], let url = HistoryItem.parseUrl(from: data) {
            return url.path
        }
        return nil
    }
}

enum SearchFold {
    static func fold(_ string: String) -> String {
        string.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
    }
}

enum SearchRanker {
    /// Higher is better. Tokens must already be folded.
    static func score(query: String, tokens: [String], haystack: String) -> Int {
        guard !tokens.isEmpty else { return 0 }
        for token in tokens where !haystack.contains(token) {
            return 0
        }
        var score = 10 // all tokens present
        if haystack.contains(query) {
            score += 40
            if haystack.hasPrefix(query) || haystack.contains(" " + query) {
                score += 30
            }
        }
        // Fuzzy subsequence only for short haystacks — avoids 50 KB "matches" on 3 letters.
        if query.count >= 3, haystack.count <= 2000, isSubsequence(query, of: haystack) {
            score += 5
        }
        return score
    }

    static func isSubsequence(_ needle: String, of haystack: String) -> Bool {
        guard !needle.isEmpty else { return true }
        var n = needle.startIndex
        for ch in haystack where ch == needle[n] {
            n = needle.index(after: n)
            if n == needle.endIndex { return true }
        }
        return false
    }
}

/// Serial background index of folded searchable strings keyed by fsId.
final class SearchIndex {
    private let queue = DispatchQueue(label: "VaultClip.SearchIndex", qos: .userInitiated)
    private var texts: [UUID: String] = [:]
    private var order: [UUID] = []
    private var built = false

    var isBuilt: Bool {
        queue.sync { built }
    }

    func invalidate() {
        queue.async {
            self.texts = [:]
            self.order = []
            self.built = false
        }
    }

    func replaceAll(sources: [SearchSource], cache: HistoryCache, completion: (() -> Void)? = nil) {
        queue.async {
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            var map: [UUID: String] = [:]
            var order: [UUID] = []
            for source in sources {
                let folded = Self.foldedText(for: source, cache: cache)
                guard !folded.isEmpty else { continue }
                map[source.fsId] = folded
                order.append(source.fsId)
            }
            self.texts = map
            self.order = order
            self.built = true
            completion?()
        }
    }

    func upsert(source: SearchSource, cache: HistoryCache) {
        queue.async {
            guard self.built else { return }
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            let folded = Self.foldedText(for: source, cache: cache)
            if folded.isEmpty {
                self.texts.removeValue(forKey: source.fsId)
                self.order.removeAll { $0 == source.fsId }
            } else {
                self.texts[source.fsId] = folded
                if !self.order.contains(source.fsId) {
                    self.order.insert(source.fsId, at: 0)
                }
            }
        }
    }

    func remove(id: UUID) {
        queue.async {
            self.texts.removeValue(forKey: id)
            self.order.removeAll { $0 == id }
        }
    }

    func clear() {
        queue.async {
            self.texts = [:]
            self.order = []
            self.built = true
        }
    }

    func search(query: String, visibleIds: [UUID], copiedAt: [UUID: Date], completion: @escaping ([UUID]) -> Void) {
        let foldedQuery = SearchFold.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        queue.async {
            guard !foldedQuery.isEmpty else {
                DispatchQueue.main.async { completion(visibleIds) }
                return
            }
            let tokens = foldedQuery.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
            var ranked: [(UUID, Int, Date)] = []
            for id in visibleIds {
                guard let haystack = self.texts[id] else { continue }
                let score = SearchRanker.score(query: foldedQuery, tokens: tokens, haystack: haystack)
                guard score > 0 else { continue }
                ranked.append((id, score, copiedAt[id] ?? .distantPast))
            }
            ranked.sort {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.2 > $1.2
            }
            DispatchQueue.main.async { completion(ranked.map(\.0)) }
        }
    }

    private static func foldedText(for source: SearchSource, cache: HistoryCache) -> String {
        SearchFold.fold(HistoryItemText.searchableText(for: source, cache: cache))
    }
}

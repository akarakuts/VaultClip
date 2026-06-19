//
//  SearchEngine.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import Foundation

struct SearchQuery: Hashable, Equatable {
    
    var query: String
    
    // Enfore the data invariant
    private init(query: String) {
        self.query = query
    }
    
    static func fromRawText(_ str: String) -> SearchQuery {
        return SearchQuery(query: str)
    }
}

public class SearchResult {
    
    var query: SearchQuery
    var results: [Int] = []
    var items: Int
    var completed: Int = 0
    
    var isFinished: Bool {
        return completed == items
    }
    
    init(query: SearchQuery, items: Int) {
        self.query = query
        self.items = items
    }
    
    func addResult(_ i: Int) {
        results.append(i)
        results.sort()
        completed += 1
    }
    
    func recordFailure() {
        completed += 1
    }
}

public class SearchEngine {
    
    private var results = [SearchQuery: SearchResult]()
    private var pendingCompletions = [SearchQuery: [(SearchResult) -> Void]]()
    private let stateQueue = DispatchQueue(label: "SearchEngineStateQueue")
    private let searchQueue = DispatchQueue(label: "SearchEngineWorkerQueue", qos: .userInitiated)
    
    private let data: [String]
    /// Maps each searchable string index to its index in the full history array.
    private let historyIndices: [Int]
    
    init(historyItems: [HistoryItem]) {
        var strings: [String] = []
        var indices: [Int] = []
        for (index, item) in historyItems.enumerated() {
            if item.isPassword {
                let searchable = [item.passwordComment, item.passwordLogin, item.passwordURL]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                guard !searchable.isEmpty else { continue }
                strings.append(searchable)
            } else {
                strings.append(HistoryItemText.getString(forItem: item, listMode: .history))
            }
            indices.append(index)
        }
        self.data = strings
        self.historyIndices = indices
    }
    
    /// Test helper — `historyIndices[i]` is the history index for `data[i]`.
    init(data: [String], historyIndices: [Int]) {
        precondition(data.count == historyIndices.count)
        self.data = data
        self.historyIndices = historyIndices
    }
    
    public func search(query: String, completion: @escaping (SearchResult) -> Void) {
        let searchQuery = SearchQuery.fromRawText(query)

        var cachedResult: SearchResult?
        let shouldStartSearch = stateQueue.sync { () -> Bool in
            if let result = results[searchQuery] {
                cachedResult = result
                return false
            }
            cachedResult = nil
            if pendingCompletions[searchQuery] != nil {
                pendingCompletions[searchQuery]?.append(completion)
                return false
            }
            pendingCompletions[searchQuery] = [completion]
            return true
        }
        if let cachedResult {
            completion(cachedResult)
            return
        }
        guard shouldStartSearch else { return }

        searchQueue.async {
            let searchResult = SearchResult(query: searchQuery, items: self.data.count)
            for (i, d) in self.data.enumerated() {
                if performSearch(needle: searchQuery.query, haystack: d) {
                    searchResult.addResult(self.historyIndices[i])
                }
                else {
                    searchResult.recordFailure()
                }
            }

            let completions = self.stateQueue.sync { () -> [(SearchResult) -> Void] in
                self.results[searchQuery] = searchResult
                return self.pendingCompletions.removeValue(forKey: searchQuery) ?? []
            }
            completions.forEach { $0(searchResult) }
        }
    }
}

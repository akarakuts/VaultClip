//
//  CellHeightCache.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class CellHeightsCache {
    
    struct Context: Equatable {
        var cellWidth: CGFloat
        var isRichText: Bool
        var displaySignature: String
    }
    
    var caches: [String: Cache<CGFloat, UUID, Context>]
    
    
    init() {
        caches = [:]
    }
    
    func createCache(forCellIdentifier cellIdentifier: String) {
        caches[cellIdentifier] = Cache()
    }
    
    func cellHeight(forId id: UUID, withCellIdentifier cellIdentifier: String, cellWidth: CGFloat, isRichText: Bool, displaySignature: String) -> CGFloat? {
        if !caches.keys.contains(cellIdentifier) {
            createCache(forCellIdentifier: cellIdentifier)
        }
        
        return caches[cellIdentifier]?.cellHeight(forId: id, withContext: Context(cellWidth: cellWidth, isRichText: isRichText, displaySignature: displaySignature))
    }
    
    func storeCellHeight(_ height: CGFloat, forId id: UUID, withCellIdentifier cellIdentifier: String, cellWidth: CGFloat, isRichText: Bool, displaySignature: String) {
        if !caches.keys.contains(cellIdentifier) {
            createCache(forCellIdentifier: cellIdentifier)
        }
        
        caches[cellIdentifier]?.storeCellHeight(height, forId: id, withContext: Context(cellWidth: cellWidth, isRichText: isRichText, displaySignature: displaySignature))
    }
    
    func removeCellHeight(forId id: UUID) {
        for (k,_) in caches {
            caches[k]?.removeCellHeight(forId: id)
        }
    }
    
    func clearCache() {
        for (k,_) in caches {
            caches[k]?.clearCache()
        }
    }
}

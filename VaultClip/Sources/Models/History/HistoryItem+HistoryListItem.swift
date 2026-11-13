//
//  HistoryItem+HistoryListItem.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension HistoryItem {
    
    func getTableViewItemType() -> HistoryListItem.Type {
        if hasRasterImage() {
            return HistoryTiffCellView.self
        }
        if getFileUrl() != nil {
            // The thumbnail cell generates previews asynchronously; classifying here must
            // never block on QuickLook (P8.1: the old sync QLThumbnailCreate froze the main thread).
            return HistoryFileThumbnailCellView.self
        }
        if getColor() != nil {
            return HistoryColorCellView.self
        }
        if getPdf() != nil {
            return HistoryPdfCellView.self
        }
        return HistoryTextCellView.self
    }
}

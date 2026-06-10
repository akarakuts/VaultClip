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
            if getThumbnailImage() != nil {
                return HistoryFileThumbnailCellView.self
            }
            return HistoryFileIconCellView.self
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

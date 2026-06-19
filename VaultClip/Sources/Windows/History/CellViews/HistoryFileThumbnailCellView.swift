//
//  HistoryFileThumbnailCellView.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import QuickLook
import Quartz

class HistoryFileThumbnailCellView: HistoryItemBaseCellView, HistoryListItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.historyFileThumbnailCellView)
    }
    
    static let fileNamePadding = HistoryListTheme.metrics.thumbnailFileNamePadding
    
    static let imageSize = HistoryListTheme.metrics.thumbnailPreviewSize
    
    static let imageTopPadding = HistoryListTheme.metrics.thumbnailTopPadding
    
    let previewView = NSImageView(frame: .zero)
    
    override func commonInit() {
        super.commonInit()
        
        contentView.addSubview(previewView)
        
        setupPreviewView()
        setupItemTextView()
    }
    
    func setupPreviewView() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.imageAlignment = .alignTopLeft
        previewView.imageScaling = .scaleProportionallyUpOrDown
        previewView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.imageTopPadding).isActive = true
        previewView.leadingAnchor.constraint(
            equalTo: sourceAppIconView.trailingAnchor,
            constant: HistoryItemBaseCellView.sourceAppIconSpacing
        ).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: Self.imageSize.width).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: Self.imageSize.height).isActive = true
        previewView.trailingAnchor.constraint(
            lessThanOrEqualTo: contentView.trailingAnchor,
            constant: -Self.fileNamePadding.right
        ).isActive = true
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.alignment = .left
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.textContainerInset = .zero
        NSLayoutConstraint.activate([
            itemTextView.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: Self.fileNamePadding.top),
            itemTextView.leadingAnchor.constraint(equalTo: sourceAppIconView.trailingAnchor, constant: HistoryItemBaseCellView.sourceAppIconSpacing),
            contentView.trailingAnchor.constraint(equalTo: itemTextView.trailingAnchor, constant: Self.fileNamePadding.right),
            contentView.bottomAnchor.constraint(equalTo: itemTextView.bottomAnchor, constant: Self.fileNamePadding.bottom),
        ])
    }
    
    func setupCell(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        guard let url = historyItem.getFileUrl() else { return }
        itemTextView.attributedText = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatFileUrl(url),
            for: historyItem,
            listMode: historyTableView.listMode
        )
        setupShortcutTextView(at: i, historyItem: historyItem)
        setHighlight(isSelected: historyTableView.isRowSelected(i))
        
        DispatchQueue.global(qos: .background).async {
            let cgImageRef = QLThumbnailImageCreate(kCFAllocatorDefault, url as CFURL, CGSize(width: 200, height: 200), [kQLThumbnailOptionIconModeKey: false, kQLThumbnailOptionScaleFactorKey: 4] as CFDictionary)
            
            DispatchQueue.main.async {
                if let cgImage = cgImageRef?.takeRetainedValue() {
                    let image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
                    self.previewView.image = image
                }
                else {
                    ErrorLogger.general.log(ClipError(.thumbnailCreationFailed, localizedDescription: "Failed to create thumbnail for file with url '\(url.path)'"))
                    self.previewView.image = nil
                }
            }
        }
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        guard let fileUrl = historyItem.getFileUrl() else {
            return ceil(contentViewInsets.yTotal)
        }
        let cellWidth = floor(historyTableView.cellWidth)
        
        let textContainerWidth = cellWidth
            - contentViewInsets.xTotal
            - fileNamePadding.xTotal
            - sourceAppIconSize
            - sourceAppIconSpacing
            - sourceAppIconTrailingInset
        
        let str = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatFileUrl(fileUrl),
            for: historyItem,
            listMode: historyTableView.listMode
        )
        
        // Calculate the height of the text
        let estHeight = str.calculateSize(withMaxWidth: textContainerWidth).height
        
        // Calculate the height of the cell
        let height = estHeight + contentViewInsets.yTotal + fileNamePadding.yTotal + imageSize.height + imageTopPadding
        
        return ceil(height)
    }
    
    static func makeItem() -> HistoryListItem {
        return HistoryFileThumbnailCellView(frame: .zero)
    }
}

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
    
    static let fileNamePadding = NSEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    
    static let imageSize = NSSize(width: 300, height: 200)
    
    static let imageTopPadding: CGFloat = 5
    
    var previewView: NSImageView!
    
    override func commonInit() {
        super.commonInit()
        
        previewView = NSImageView(frame: .zero)
        contentView.addSubview(previewView)
        
        setupPreviewView()
        setupItemTextView()
    }
    
    func setupPreviewView() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.imageAlignment = .alignTopLeft
        previewView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addConstraint(NSLayoutConstraint(item: previewView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: Self.imageTopPadding))
        contentView.addConstraint(NSLayoutConstraint(item: previewView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.fileNamePadding.left))
        previewView.widthAnchor.constraint(equalToConstant: Self.imageSize.width).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: Self.imageSize.height).isActive = true
        previewView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Self.fileNamePadding.right).isActive = true
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.alignment = .left
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.textContainerInset = .zero
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .top, relatedBy: .equal, toItem: previewView, attribute: .bottom, multiplier: 1, constant: Self.fileNamePadding.top))
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.fileNamePadding.left))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: itemTextView, attribute: .trailing, multiplier: 1, constant: Self.fileNamePadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: itemTextView, attribute: .bottom, multiplier: 1, constant: Self.fileNamePadding.bottom))
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
                    ErrorLogger.general.log(ClipError(localizedDescription: "Failed to create thumbnail for file with url '\(url.path)'"))
                    self.previewView.image = nil
                }
            }
        }
    }
    
    static func getItemHeight(withHistoryTableView historyTableView: HistoryTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        let cellWidth = floor(historyTableView.cellWidth)
        
        let textContainerWidth = cellWidth - contentViewInsets.xTotal - fileNamePadding.xTotal
        
        let str = HistoryItemText.appendPasswordCommentIfNeeded(
            to: formatFileUrl(historyItem.getFileUrl()!),
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

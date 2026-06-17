//
//  FormatPdf.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

func formatPdfDisplay(_ label: String) -> NSAttributedString {
    NSAttributedString(
        string: label,
        attributes: [
            .font: Constants.fonts.listFileNameText,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
        ]
    )
}

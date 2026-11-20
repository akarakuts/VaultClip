//
//  HistoryTableViewDelegate.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

protocol HistoryTableViewDelegate {
    
    func historyTableView(_ historyTableView: HistoryTableView, selectedDidChange selected: Int?)
    
    func historyTableView(_ historyTableView: HistoryTableView, didMoveItem from: Int, to: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, toggleFavoriteAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, saveToPasswordsAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, removeFromPasswordsAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, editPasswordEntryAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordLoginAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordValueAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, copyPasswordURLAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, openPasswordURLAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, deleteItemAt row: Int)

    /// Double-click / ⏎ on a row.
    func historyTableView(_ historyTableView: HistoryTableView, pasteRowAt row: Int)

    /// Hover overlay buttons (U15).
    func historyTableView(_ historyTableView: HistoryTableView, performRowAction action: RowActionButtonID, at row: Int)

    /// Registry-backed context menu entries (U17); selection already includes `row`.
    func historyTableView(_ historyTableView: HistoryTableView, performCommand command: PanelCommandID, at row: Int)

    func historyTableView(_ historyTableView: HistoryTableView, filterByAppAt row: Int)
}

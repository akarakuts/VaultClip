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
    
    func historyTableView(_ historyTableView: HistoryTableView, editPasswordCommentAt row: Int)
    
    func historyTableView(_ historyTableView: HistoryTableView, deleteItemAt row: Int)
}

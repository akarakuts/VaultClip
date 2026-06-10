//
//  XCUIApplication+VaultClip.swift
//  VaultClipUITests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest

extension XCUIApplication {
    
    var historyTableView: XCUIElement {
        return historyWindow.tables[Accessibility.identifiers.historyTableView]
    }
    
    var historyTableViewItems: XCUIElementQuery {
        return historyTableView.cells
    }
    
    func getHistoryTableViewCell(at i: Int) -> XCUIElement {
        return historyTableViewItems.element(boundBy: i)
    }
    
    func getHistoryTableViewCellTextView(at i: Int) -> XCUIElement {
        return getHistoryTableViewCell(at: i).children(matching: .textView).matching(identifier: Accessibility.identifiers.historyItemTextView).element
    }
    
    func getHistoryTableViewItemString(at i: Int) -> String? {
        return getHistoryTableViewCellTextView(at: i).value as? String
    }
    
    func getHistoryTableViewCellType(at i: Int) -> String {
        return getHistoryTableViewCell(at: i).label
    }
}

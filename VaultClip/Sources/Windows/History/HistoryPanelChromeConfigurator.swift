//
// HistoryPanelChromeConfigurator — programmatic layout and typography for the history panel.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa

enum HistoryPanelChromeConfigurator {

  /// Replaces the storyboard placeholder table with a clean programmatic table.
  static func configurePanelLayout(
    in view: NSView,
    historyListView: inout HistoryTableView
  ) {
    view.autoresizingMask = [.width, .height]

    guard let scrollView = historyListView.enclosingScrollView else {
      historyListView.applyPlainListAppearance()
      return
    }

    let tableView = HistoryTableView(frame: scrollView.contentView.bounds)
    tableView.autoresizingMask = [.width]
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.usesAlternatingRowBackgroundColors = false

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("HistoryListColumn"))
    column.width = max(1, floor(scrollView.contentView.bounds.width))
    column.minWidth = 1
    column.maxWidth = 10000
    tableView.addTableColumn(column)

    scrollView.documentView = tableView
    historyListView = tableView
    historyListView.applyPlainListAppearance()
    (scrollView.contentView as? HistoryListClipView)?.enforceDocumentWidth()
  }

  /// Fonts/heights only. Column constraints are owned by `installProgrammaticPanelLayout` (U08).
  static func applyChromeMetrics(
    root: NSView,
    historyListView: HistoryTableView,
    searchBar: NSTextField,
    itemGroupScrollView: HistoryTabBarView,
    itemCountLabel: NSTextField,
    emptyListLabel: NSTextField?
  ) {
    _ = historyListView
    for constraint in searchBar.constraints where constraint.firstAttribute == .height {
      constraint.constant = PanelChrome.Metrics.searchBarHeight
    }
    for constraint in itemGroupScrollView.constraints where constraint.firstAttribute == .height {
      constraint.constant = PanelChrome.Metrics.tabBarHeight
    }

    // Large "VaultClip" title removed — reclaim vertical space (U06).
    hidePanelTitleLabel(in: root, excluding: [searchBar, itemCountLabel, emptyListLabel].compactMap { $0 })
  }

  static func styleHistoryChrome(
    searchBar: NSTextField,
    itemCountLabel: NSTextField
  ) {
    itemCountLabel.font = NSFont.monospacedDigitSystemFont(
      ofSize: PanelChrome.Typography.countSize,
      weight: .regular
    )
    itemCountLabel.textColor = .secondaryLabelColor
    itemCountLabel.lineBreakMode = .byTruncatingTail
    itemCountLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    if let fieldCell = searchBar.cell as? NSTextFieldCell {
      fieldCell.font = NSFont.monospacedSystemFont(
        ofSize: PanelChrome.Typography.chromeSize,
        weight: .regular
      )
    }
  }

  // MARK: - Private

  private static func hidePanelTitleLabel(in root: NSView, excluding excluded: [NSTextField]) {
    for subview in root.subviews {
      if let field = subview as? NSTextField,
         !excluded.contains(where: { $0 === field }),
         !field.isEditable,
         field.stringValue.localizedCaseInsensitiveContains("VaultClip")
          || field.stringValue.localizedCaseInsensitiveContains("Yippy") {
        field.isHidden = true
        field.stringValue = ""
      }
      hidePanelTitleLabel(in: subview, excluding: excluded)
    }
  }
}

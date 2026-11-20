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

  static func applyChromeMetrics(
    root: NSView,
    historyListView: HistoryTableView,
    searchBar: NSTextField,
    itemGroupScrollView: HistoryTabBarView,
    itemCountLabel: NSTextField,
    emptyListLabel: NSTextField?
  ) {
    guard let scrollView = historyListView.enclosingScrollView else { return }

    func visit(_ view: NSView) {
      for constraint in view.constraints {
        applyChromeMetric(
          to: constraint,
          scrollView: scrollView,
          searchBar: searchBar,
          itemGroupScrollView: itemGroupScrollView,
          itemCountLabel: itemCountLabel
        )
      }
      view.subviews.forEach(visit)
    }
    visit(root)

    for constraint in searchBar.constraints where constraint.firstAttribute == .height {
      constraint.constant = PanelChrome.metrics.searchBarHeight
    }
    for constraint in itemGroupScrollView.constraints where constraint.firstAttribute == .height {
      constraint.constant = PanelChrome.metrics.tabBarHeight
    }

    // Large "VaultClip" title removed — reclaim vertical space (U06).
    hidePanelTitleLabel(in: root, excluding: [searchBar, itemCountLabel, emptyListLabel].compactMap { $0 })
  }

  static func styleHistoryChrome(
    searchBar: NSTextField,
    itemCountLabel: NSTextField
  ) {
    itemCountLabel.font = NSFont.monospacedDigitSystemFont(
      ofSize: PanelChrome.typography.countSize,
      weight: .regular
    )
    itemCountLabel.textColor = .secondaryLabelColor
    itemCountLabel.lineBreakMode = .byTruncatingTail
    itemCountLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    if let fieldCell = searchBar.cell as? NSTextFieldCell {
      fieldCell.font = NSFont.monospacedSystemFont(
        ofSize: PanelChrome.typography.chromeSize,
        weight: .regular
      )
    }
  }

  // MARK: - Private

  private static func applyChromeMetric(
    to constraint: NSLayoutConstraint,
    scrollView: NSScrollView,
    searchBar: NSTextField,
    itemGroupScrollView: HistoryTabBarView,
    itemCountLabel: NSTextField
  ) {
    let leadingItems: [NSObject] = [searchBar, scrollView, itemGroupScrollView]
    let trailingItems: [NSObject] = [searchBar, scrollView, itemGroupScrollView, itemCountLabel]

    if constraint.firstAttribute == .leading,
       let first = constraint.firstItem as? NSObject,
       leadingItems.contains(where: { $0 === first }) {
      constraint.constant = PanelChrome.metrics.panelContentInset
    }
    if constraint.firstAttribute == .trailing,
       let second = constraint.secondItem as? NSObject,
       trailingItems.contains(where: { $0 === second }) {
      constraint.constant = PanelChrome.metrics.panelContentInset
    }
    if constraint.firstItem as? NSObject === searchBar,
       constraint.firstAttribute == .top,
       constraint.secondItem is NSTextField {
      constraint.constant = PanelChrome.metrics.titleToSearchSpacing
    }
    if constraint.firstItem as? NSObject === itemGroupScrollView,
       constraint.firstAttribute == .top,
       constraint.secondItem as? NSObject === searchBar {
      constraint.constant = PanelChrome.metrics.searchToTabsSpacing
    }
    if constraint.firstItem as? NSObject === scrollView,
       constraint.firstAttribute == .top,
       constraint.secondItem as? NSObject === itemGroupScrollView {
      constraint.constant = PanelChrome.metrics.tabsToListSpacing
    }
    if constraint.firstAttribute == .top,
       constraint.secondItem == nil,
       let first = constraint.firstItem as? NSTextField,
       first !== searchBar,
       first !== itemCountLabel {
      constraint.constant = PanelChrome.metrics.headerTopInset
    }
  }

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

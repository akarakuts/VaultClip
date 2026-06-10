//
//  HistoryViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

class HistoryViewController: NSViewController {
    
    private var historyUnsubscribe: (() -> Void)?
    
    @IBOutlet var historyListView: HistoryTableView!
    
    @IBOutlet var itemGroupScrollView: HistoryTabBarView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!
    
    var historyPanel = HistoryPanel(history: State.main.history, items: [])
    
    var searchEngine = SearchEngine(historyItems: [])
    
    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    let listMode = BehaviorRelay<HistoryListMode>(value: .history)
    
    var isRichText = Settings.main.showsRichText
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    private var emptyListLabel: NSTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleHistoryChrome()
        historyListView.historyDelegate = self
        
        historyUnsubscribe = State.main.history.subscribe(onNext: onHistoryChange)
        
        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
        itemGroupScrollView.delegate = self
        itemGroupScrollView.configure(with: HistoryListMode.tabDefinitions)
        listMode
            .bind(onNext: { [weak self] mode in
                self?.itemGroupScrollView.selectTab(at: mode.rawValue)
            })
            .disposed(by: disposeBag)
        
        listMode
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if self.searchBar.stringValue.isEmpty {
                    self.applyListFilter()
                } else {
                    self.runSearch()
                }
                self.resetSelected()
            })
            .disposed(by: disposeBag)
        
        setupEmptyListLabel()
        
        Observable.combineLatest(
            results,
            selected.distinctUntilChanged().withPrevious(startWith: selected.value)
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: onAllChange)
            .disposed(by: disposeBag)
        
        searchBar.delegate = self
        resetSelected()
        
        ClipHotKeys.downArrow.onDown(goToNextItem)
        ClipHotKeys.downArrow.onLong(goToNextItem)
        ClipHotKeys.pageDown.onDown(goToNextItem)
        ClipHotKeys.pageDown.onLong(goToNextItem)
        ClipHotKeys.upArrow.onDown(goToPreviousItem)
        ClipHotKeys.upArrow.onLong(goToPreviousItem)
        ClipHotKeys.pageUp.onDown(goToPreviousItem)
        ClipHotKeys.pageUp.onLong(goToPreviousItem)
        ClipHotKeys.escape.onDown(close)
        ClipHotKeys.return.onDown(pasteSelected)
        ClipHotKeys.ctrlAltCmdLeftArrow.onDown { State.main.panelPosition.accept(.left) }
        ClipHotKeys.ctrlAltCmdRightArrow.onDown { State.main.panelPosition.accept(.right) }
        ClipHotKeys.ctrlAltCmdDownArrow.onDown { State.main.panelPosition.accept(.bottom) }
        ClipHotKeys.ctrlAltCmdUpArrow.onDown { State.main.panelPosition.accept(.top) }
        ClipHotKeys.ctrlDelete.onDown(deleteSelected)
        ClipHotKeys.ctrlSpace.onDown(togglePreview)
        ClipHotKeys.cmdBackslash.onDown(focusSearchBar)
        ClipHotKeys.ctrlLeftBracket.onDown(switchToPreviousTab)
        ClipHotKeys.ctrlRightBracket.onDown(switchToNextTab)
        
        // Paste hot keys
        ClipHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        ClipHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        ClipHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        ClipHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        ClipHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        ClipHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        ClipHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        ClipHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        ClipHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        ClipHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        bindHotKeyToHistoryWindow(ClipHotKeys.downArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.upArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.return, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.escape, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.pageDown, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.pageUp, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlAltCmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlAltCmdRightArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlAltCmdDownArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlAltCmdUpArrow, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd0, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd1, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd2, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd3, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd4, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd5, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd6, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd7, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd8, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.cmd9, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlDelete, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlSpace, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlLeftBracket, disposeBag: disposeBag)
        bindHotKeyToHistoryWindow(ClipHotKeys.ctrlRightBracket, disposeBag: disposeBag)
        
        searchBar.resignFirstResponder()
    }
    
    deinit {
        historyUnsubscribe?()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        isPreviewShowing = false
        resetSelected()
    }
    
    func resetSelected() {
        if historyPanel.items.count > 0 {
            selected.accept(0)
        }
        else {
            selected.accept(nil)
        }
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        if !searchBar.stringValue.isEmpty {
            runSearch()
        } else {
            applyListFilter()
        }
        switch change {
        case .insert(let i) where i == 0 && listMode.value == .history:
            incrementSelected()
        case .favoriteChanged(let item, _), .passwordChanged(let item, _):
            historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
            applyListFilter()
            let visible = itemsForActiveListMode(from: State.main.history.items)
            if !visible.contains(where: { $0.fsId == item.fsId }) {
                resetSelected()
            } else {
                refreshHistoryItemDisplay(item)
            }
        case .pinnedLimitExceeded(let current, let max):
            itemCountLabel.stringValue = "\(current) items (limit \(max), pinned items protected)"
        default:
            break
        }
    }
    
    func itemsForActiveListMode(from history: [HistoryItem]) -> [HistoryItem] {
        switch listMode.value {
        case .history:
            return history.filter { !$0.isPinnedFromPruning }
        case .favorites:
            return history.filter(\.isFavorite)
        case .passwords:
            return history.filter(\.isPassword)
        }
    }
    
    func applyListFilter() {
        let baseItems = itemsForActiveListMode(from: State.main.history.items)
        updateSearchEngine(items: baseItems)
        results.accept(Results(items: baseItems, isSearchResult: false))
        updateEmptyListLabel(for: listMode.value, visible: baseItems.isEmpty)
    }
    
    /// Reloads a row when favorite/password metadata changes without altering the item list.
    private func refreshHistoryItemDisplay(_ item: HistoryItem) {
        historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
        let visibleItems = itemsForActiveListMode(from: State.main.history.items)
        guard let row = visibleItems.firstIndex(where: { $0.fsId == item.fsId }) else { return }
        historyListView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
        historyListView.reloadItem(row)
    }
    
    func updateSearchEngine(items: [HistoryItem]) {
        self.searchEngine = SearchEngine(historyItems: items)
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
        if results.items != self.historyPanel.items {
                self.itemCountLabel.stringValue = self.countLabelText(for: results)
                self.historyPanel = HistoryPanel(history: State.main.history, items: results.items)
                self.historyListView.reloadData(self.historyPanel.items, isRichText: self.isRichText, listMode: self.listMode.value)
                self.updateEmptyListLabel(
                    for: self.listMode.value,
                    visible: !results.isSearchResult && results.items.isEmpty
                )
            }
        
        if let previous = selected.0 {
            self.historyListView.deselectItem(previous)
            self.historyListView.reloadItem(previous)
        }
        if let selected = selected.1, selected >= 0, selected < self.historyPanel.items.count {
            let currentSelection = self.historyListView.selected
            if currentSelection == nil || currentSelection != selected {
                self.historyListView.selectItem(selected)
            }
            self.historyListView.reloadItem(selected)
            
            if self.isPreviewShowing {
                State.main.previewHistoryItem.accept(self.historyPanel.items[selected])
            }
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        historyListView.reloadData(historyPanel.items, isRichText: isRichText, listMode: listMode.value)
    }
    
    func bindHotKeyToHistoryWindow(_ hotKey: ClipHotKey, disposeBag: DisposeBag) {
        State.main.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [] in
                hotKey.isPaused = !$0
            })
            .disposed(by: disposeBag)
    }
    
    func goToNextItem() {
        incrementSelected()
    }
    
    func goToPreviousItem() {
        decrementSelected()
    }
    
    func pasteSelected() {
        if let selected = self.historyListView.selected {
            paste(selected: selected)
        }
    }
    
    func deleteSelected() {
        if let row = self.historyListView.selected {
            self.selected.accept(historyPanel.delete(displayedIndex: row))
        }
    }
    
    func switchToPreviousTab() {
        listMode.accept(listMode.value.previous())
    }
    
    func switchToNextTab() {
        listMode.accept(listMode.value.next())
    }
    
    func close() {
        isPreviewShowing = false
        State.main.isHistoryPanelShown.accept(false)
        State.main.previewHistoryItem.accept(nil)
        resetSelected()
    }
    
    func shortcutPressed(key: Int) {
        paste(selected: key)
    }
    
    func togglePreview() {
        if let row = historyListView.selected, row >= 0, row < historyPanel.items.count {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                State.main.previewHistoryItem.accept(historyPanel.items[row])
            } else {
                State.main.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }
    
    func runSearch() {
        let query = searchBar.stringValue
        let baseItems = itemsForActiveListMode(from: State.main.history.items)
        if query.isEmpty {
            applyListFilter()
            return
        }
        
        updateSearchEngine(items: baseItems)
        searchEngine.search(query: query, completion: { result in
            DispatchQueue.main.async {
                guard self.searchBar.stringValue == result.query.query else { return }
                
                var filteredData = [HistoryItem]()
                for index in result.results {
                    guard index >= 0, index < baseItems.count else { continue }
                    filteredData.append(baseItems[index])
                }
                self.results.accept(Results(items: filteredData, isSearchResult: true))
            }
        })
    }
    
    private func incrementSelected() {
        guard let s = selected.value else {
            if historyPanel.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s < historyPanel.items.count - 1 {
            selected.accept(s + 1)
        }
    }
    
    private func decrementSelected() {
        guard let s = selected.value else {
            if historyPanel.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s > 0 {
            selected.accept(s - 1)
        }
    }
    
    private func paste(selected: Int) {
        self.close()
        historyPanel.paste(displayedIndex: selected)
    }
    
    private func countLabelText(for results: Results) -> String {
        let count = results.items.count
        if results.isSearchResult {
            return "\(count) matches"
        }
        switch listMode.value {
        case .history:
            return "\(count) items"
        case .favorites:
            return count == 1 ? "1 favorite" : "\(count) favorites"
        case .passwords:
            return count == 1 ? "1 password" : "\(count) passwords"
        }
    }
    
    private func setupEmptyListLabel() {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: HistoryListTheme.typography.chromeSize)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: historyListView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: historyListView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: historyListView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: historyListView.trailingAnchor, constant: -20),
        ])
        emptyListLabel = label
    }
    
    private func emptyStateMessage(for mode: HistoryListMode) -> String? {
        switch mode {
        case .history:
            return nil
        case .favorites:
            return "No favorites yet. Right-click an item → Add to Favorites"
        case .passwords:
            return "No passwords saved. Right-click an item → Save to Passwords…"
        }
    }
    
    private func updateEmptyListLabel(for mode: HistoryListMode, visible: Bool) {
        guard mode != .history else {
            emptyListLabel?.isHidden = true
            return
        }
        emptyListLabel?.stringValue = emptyStateMessage(for: mode) ?? ""
        emptyListLabel?.isHidden = !visible
    }
    
    /// Aligns search and count labels with the history list typography.
    private func styleHistoryChrome() {
        itemCountLabel.font = NSFont.monospacedDigitSystemFont(
            ofSize: HistoryListTheme.typography.countSize,
            weight: .regular
        )
        itemCountLabel.textColor = .secondaryLabelColor
        
        if let fieldCell = searchBar.cell as? NSTextFieldCell {
            fieldCell.font = NSFont.monospacedSystemFont(
                ofSize: HistoryListTheme.typography.chromeSize,
                weight: .regular
            )
        }
    }
}

extension HistoryViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension HistoryViewController: HistoryTableViewDelegate {
    func historyTableView(_ historyTableView: HistoryTableView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, didMoveItem from: Int, to: Int) {
        historyPanel.move(displayedFrom: from, to: to)
        selected.accept(to)
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, toggleFavoriteAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.toggleFavorite(item: historyPanel.items[row])
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, saveToPasswordsAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        let item = historyPanel.items[row]
        guard let comment = PasswordCommentPrompt.run(
            title: "Save to Passwords",
            message: "Add an optional comment for this password."
        ) else { return }
        historyPanel.saveToPasswords(item: item, comment: comment)
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, removeFromPasswordsAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        historyPanel.removeFromPasswords(item: historyPanel.items[row])
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, editPasswordCommentAt row: Int) {
        guard row >= 0, row < historyPanel.items.count else { return }
        let item = historyPanel.items[row]
        guard let comment = PasswordCommentPrompt.run(
            title: "Edit Comment",
            message: "Update the comment for this saved password.",
            initialValue: item.passwordComment
        ) else { return }
        historyPanel.editPasswordComment(item: item, comment: comment)
    }
    
    func historyTableView(_ historyTableView: HistoryTableView, deleteItemAt row: Int) {
        selected.accept(historyPanel.delete(displayedIndex: row))
    }
}

extension HistoryViewController: HistoryTabBarViewDelegate {
    func historyTabBarView(_ tabBar: HistoryTabBarView, didSelect mode: HistoryListMode) {
        listMode.accept(mode)
    }
}

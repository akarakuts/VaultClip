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

    private var injectedState: State?
    private var injectedSettings: Settings?

    private var appState: State { injectedState ?? AppEnvironment.shared.state }
    private var appSettings: Settings { injectedSettings ?? AppEnvironment.shared.settings }

    /// Called from `Controller.createHistoryWindowController` before the window loads.
    func configure(state: State, settings: Settings) {
        injectedState = state
        injectedSettings = settings
    }
    
    @IBOutlet var historyListView: HistoryTableView!
    
    @IBOutlet var itemGroupScrollView: HistoryTabBarView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!
    
    lazy var historyPanel = HistoryPanel(history: appState.history, items: [])
    
    var searchEngine = SearchEngine(historyItems: [])
    
    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    let listMode = BehaviorRelay<HistoryListMode>(value: .history)
    
    var isRichText = true
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    private var emptyListLabel: NSTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isRichText = appSettings.showsRichText
        
        configurePanelLayout()
        applyPanelChromeMetrics()
        styleHistoryChrome()
        searchBar.placeholderString = L10n.searchPlaceholder
        historyListView.historyDelegate = self
        
        appState.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
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
                DispatchQueue.main.async {
                    self.alignHistoryListToScrollView()
                }
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

        historyUnsubscribe = appState.history.subscribe(onNext: { [weak self] history, change in
            DispatchQueue.main.async {
                self?.onHistoryChange(history, change: change)
            }
        })

        appState.isHistoryPanelShown
            .distinctUntilChanged()
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.refreshHistoryListOnPanelOpen()
            })
            .disposed(by: disposeBag)
        
        searchBar.delegate = self
        applyListFilter()
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
        ClipHotKeys.ctrlAltCmdLeftArrow.onDown { self.appState.panelPosition.accept(.left) }
        ClipHotKeys.ctrlAltCmdRightArrow.onDown { self.appState.panelPosition.accept(.right) }
        ClipHotKeys.ctrlAltCmdDownArrow.onDown { self.appState.panelPosition.accept(.bottom) }
        ClipHotKeys.ctrlAltCmdUpArrow.onDown { self.appState.panelPosition.accept(.top) }
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
        refreshHistoryListOnPanelOpen()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        alignHistoryListToScrollView()
        DispatchQueue.main.async { [weak self] in
            self?.alignHistoryListToScrollView()
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        guard appState.isHistoryPanelShown.value else { return }
        historyListView.syncColumnWidthToScrollView()
    }

    /// Clears stale search / height cache and reloads when the panel becomes visible.
    private func refreshHistoryListOnPanelOpen() {
        let baseItems = itemsForActiveListMode(from: appState.history.items)
        if !searchBar.stringValue.isEmpty, baseItems.count > 0, results.value.items.isEmpty {
            searchBar.stringValue = ""
        }
        historyListView.cellHeightsCache.clearCache()
        applyListFilter()
        resetSelected()
        alignHistoryListToScrollView()
    }
    
    /// Syncs column width and row heights after the panel window has its final size.
    func alignHistoryListAfterWindowFrameChange() {
        alignHistoryListToScrollView()
    }
    
    private func alignHistoryListToScrollView() {
        guard isViewLoaded, appState.isHistoryPanelShown.value else { return }
        view.window?.layoutIfNeeded()
        view.layoutSubtreeIfNeeded()
        historyListView.enclosingScrollView?.layoutSubtreeIfNeeded()
        historyListView.syncColumnWidthToScrollView()
        historyListView.remeasureVisibleRows()
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
        case .insert(let i) where i == 0:
            if !searchBar.stringValue.isEmpty {
                searchBar.stringValue = ""
                applyListFilter()
            }
            syncHistoryTableToResults()
            if listMode.value == .history, searchBar.stringValue.isEmpty {
                selected.accept(0)
            }
        case .favoriteChanged(let item, _), .passwordChanged(let item, _):
            historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
            applyListFilter()
            syncHistoryTableToResults()
            let visible = itemsForActiveListMode(from: appState.history.items)
            if !visible.contains(where: { $0.fsId == item.fsId }) {
                resetSelected()
            } else {
                refreshHistoryItemDisplay(item)
            }
        case .pinnedLimitExceeded(let current, let max):
            itemCountLabel.stringValue = L10n.countPinnedLimit(current: current, max: max)
        case .initial, .delete, .clear, .move, .itemLimitDecreased:
            syncHistoryTableToResults()
        default:
            break
        }
    }
    
    func itemsForActiveListMode(from history: [HistoryItem]) -> [HistoryItem] {
        switch listMode.value {
        case .history:
            return history.filter { !$0.isFavorite && !$0.isPassword }
        case .favorites:
            return history.filter(\.isFavorite)
        case .passwords:
            return history.filter(\.isPassword)
        }
    }
    
    func applyListFilter() {
        let baseItems = itemsForActiveListMode(from: appState.history.items)
        updateSearchEngine(items: baseItems)
        results.accept(Results(items: baseItems, isSearchResult: false))
        updateEmptyListLabel(for: listMode.value, visible: baseItems.isEmpty)
        syncHistoryTableToResults()
    }

    /// Pushes `results` into the table; skip row layout while the panel is hidden (wrong window size at launch).
    private func syncHistoryTableToResults() {
        guard isViewLoaded else { return }
        let current = results.value
        itemCountLabel.stringValue = countLabelText(for: current)
        historyPanel = HistoryPanel(history: appState.history, items: current.items)
        updateEmptyListLabel(
            for: listMode.value,
            visible: !current.isSearchResult && current.items.isEmpty
        )
        
        guard appState.isHistoryPanelShown.value else { return }
        
        historyListView.cellHeightsCache.clearCache()
        historyListView.reloadData(historyPanel.items, isRichText: isRichText, listMode: listMode.value)
        historyListView.layoutSubtreeIfNeeded()
        if let first = current.items.first {
            let preview = HistoryItemText.getString(forItem: first, listMode: listMode.value)
            PasteboardDiagnostics.log(
                "ui reload rows=\(current.items.count) search=\(current.isSearchResult) mode=\(listMode.value) top=\(preview.prefix(40))"
            )
        } else {
            PasteboardDiagnostics.log(
                "ui reload rows=0 search=\(current.isSearchResult) mode=\(listMode.value)"
            )
        }
    }
    
    /// Reloads a row when favorite/password metadata changes without altering the item list.
    private func refreshHistoryItemDisplay(_ item: HistoryItem) {
        historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
        let visibleItems = itemsForActiveListMode(from: appState.history.items)
        guard let row = visibleItems.firstIndex(where: { $0.fsId == item.fsId }) else { return }
        historyListView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
        historyListView.reloadItem(row)
    }
    
    func updateSearchEngine(items: [HistoryItem]) {
        self.searchEngine = SearchEngine(historyItems: items)
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
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
                appState.previewHistoryItem.accept(self.historyPanel.items[selected])
            }
        }
        historyListView.syncColumnWidthToScrollView()
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        historyListView.reloadData(historyPanel.items, isRichText: isRichText, listMode: listMode.value)
    }
    
    func bindHotKeyToHistoryWindow(_ hotKey: ClipHotKey, disposeBag: DisposeBag) {
        appState.isHistoryPanelShown
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
        appState.isHistoryPanelShown.accept(false)
        appState.previewHistoryItem.accept(nil)
        resetSelected()
    }
    
    func shortcutPressed(key: Int) {
        paste(selected: key)
    }
    
    func togglePreview() {
        if let row = historyListView.selected, row >= 0, row < historyPanel.items.count {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                appState.previewHistoryItem.accept(historyPanel.items[row])
            } else {
                appState.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }
    
    func runSearch() {
        let query = searchBar.stringValue
        let baseItems = itemsForActiveListMode(from: appState.history.items)
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
                self.syncHistoryTableToResults()
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
            return L10n.countMatches(count)
        }
        switch listMode.value {
        case .history:
            return L10n.countItems(count)
        case .favorites:
            return count == 1 ? L10n.countFavoriteOne : L10n.countFavorites(count)
        case .passwords:
            return count == 1 ? L10n.countPasswordOne : L10n.countPasswords(count)
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
        guard let scrollView = historyListView.enclosingScrollView else { return }
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            label.leadingAnchor.constraint(
                greaterThanOrEqualTo: scrollView.leadingAnchor,
                constant: HistoryListTheme.metrics.scaled(20)
            ),
            label.trailingAnchor.constraint(
                lessThanOrEqualTo: scrollView.trailingAnchor,
                constant: -HistoryListTheme.metrics.scaled(20)
            ),
        ])
        emptyListLabel = label
    }
    
    private func emptyStateMessage(for mode: HistoryListMode) -> String? {
        switch mode {
        case .history:
            return nil
        case .favorites:
            return L10n.emptyFavorites
        case .passwords:
            return L10n.emptyPasswords
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
    
    private func configurePanelLayout() {
        HistoryPanelChromeConfigurator.configurePanelLayout(in: view, historyListView: &historyListView)
    }

    private func applyPanelChromeMetrics() {
        HistoryPanelChromeConfigurator.applyChromeMetrics(
            root: view,
            historyListView: historyListView,
            searchBar: searchBar,
            itemGroupScrollView: itemGroupScrollView,
            itemCountLabel: itemCountLabel,
            emptyListLabel: emptyListLabel
        )
    }

    private func styleHistoryChrome() {
        HistoryPanelChromeConfigurator.styleHistoryChrome(
            searchBar: searchBar,
            itemCountLabel: itemCountLabel
        )
    }
}

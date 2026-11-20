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
    private var settingsProvider: (() -> Settings)?

    private var appState: State { injectedState ?? AppEnvironment.shared.state }
    private var appSettings: Settings { (settingsProvider ?? { SettingsPersistence.current() })() }

    /// Called from `Controller.createHistoryWindowController` before the window loads.
    func configure(state: State, settings: @escaping () -> Settings = { SettingsPersistence.current() }) {
        injectedState = state
        settingsProvider = settings
    }
    
    @IBOutlet var historyListView: HistoryTableView!
    
    @IBOutlet var itemGroupScrollView: HistoryTabBarView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!
    
    lazy var historyPanel = HistoryPanel(
        history: appState.history,
        items: [],
        settings: { [weak self] in self?.appSettings ?? SettingsPersistence.current() },
        isPanelShown: { [weak self] in self?.appState.isHistoryPanelShown.value ?? false }
    )
    
    let searchIndex = SearchIndex()
    private var searchDebounceWork: DispatchWorkItem?

    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    let listMode = BehaviorRelay<HistoryListMode>(value: .history)
    
    var isRichText = true
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    private var emptyListLabel: NSTextField?

    private let panelKeyMonitor = PanelLocalKeyMonitor()
    
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
        
        configurePanelKeyMonitor()

        appState.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] shown in
                guard let self else { return }
                if shown {
                    self.panelKeyMonitor.start()
                } else {
                    self.panelKeyMonitor.stop()
                    self.isPreviewShowing = false
                    self.appState.previewHistoryItem.accept(nil)
                }
            })
            .disposed(by: disposeBag)
        
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
        updateSearchIndex(for: change, history: history)
        switch change {
        case .insert(let i) where i == 0:
            if !searchBar.stringValue.isEmpty {
                searchBar.stringValue = ""
            }
            applyListFilter(mutation: .insertTop)
            if listMode.value == .history {
                selected.accept(0)
            }
        case .favoriteChanged(let item, _), .passwordChanged(let item, _):
            historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
            if !searchBar.stringValue.isEmpty {
                runSearch()
            } else {
                applyListFilter(mutation: .reload)
            }
            let visible = itemsForActiveListMode(from: appState.history.items)
            if !visible.contains(where: { $0.fsId == item.fsId }) {
                resetSelected()
            } else {
                refreshHistoryItemDisplay(item)
            }
        case .pinnedLimitExceeded(let current, let max):
            itemCountLabel.stringValue = L10n.countPinnedLimit(current: current, max: max)
        default:
            if !searchBar.stringValue.isEmpty {
                runSearch()
            } else {
                applyListFilter(mutation: rowMutation(for: change, history: history))
            }
        }
    }

    private func rowMutation(for change: History.Change, history: [HistoryItem]) -> HistoryTableView.RowMutation {
        switch change {
        case .insert(let index) where index == 0:
            return .insertTop
        case .delete(let deleted):
            return .delete(deleted.fsId)
        case .move(_, let to) where history.indices.contains(to):
            return .move(history[to].fsId)
        default:
            return .reload
        }
    }

    private func updateSearchIndex(for change: History.Change, history: [HistoryItem]) {
        let cache = appState.historyCache
        switch change {
        case .initial:
            searchIndex.invalidate()
        case .clear:
            searchIndex.clear()
        case .insert(let index):
            guard history.indices.contains(index) else { return }
            searchIndex.upsert(source: SearchSource(item: history[index]), cache: cache)
        case .delete(let deleted):
            searchIndex.remove(id: deleted.fsId)
        case .itemLimitDecreased(let deletedItems):
            for item in deletedItems {
                searchIndex.remove(id: item.fsId)
            }
        case .favoriteChanged(let item, _), .passwordChanged(let item, _):
            searchIndex.upsert(source: SearchSource(item: item), cache: cache)
        case .move, .pinnedLimitExceeded:
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
    
    func applyListFilter(mutation: HistoryTableView.RowMutation = .reload) {
        let baseItems = itemsForActiveListMode(from: appState.history.items)
        // Do not rebuild a full-text engine here — SearchIndex updates incrementally / on demand (T22).
        results.accept(Results(items: baseItems, isSearchResult: false))
        updateEmptyListLabel(for: listMode.value, visible: baseItems.isEmpty)
        syncHistoryTableToResults(mutation: mutation)
    }

    /// Pushes `results` into the table; skip row layout while the panel is hidden (wrong window size at launch).
    private func syncHistoryTableToResults(mutation: HistoryTableView.RowMutation = .reload) {
        guard isViewLoaded else { return }
        let current = results.value
        itemCountLabel.stringValue = countLabelText(for: current)
        // Keep a single HistoryPanel instance; only refresh items (U05 / T38 debt).
        historyPanel.items = current.items

        updateEmptyListLabel(
            for: listMode.value,
            visible: !current.isSearchResult && current.items.isEmpty
        )
        
        guard appState.isHistoryPanelShown.value else { return }

        if current.isSearchResult || mutation == .reload {
            historyListView.reloadData(historyPanel.items, isRichText: isRichText, listMode: listMode.value)
        } else {
            historyListView.applyItemsIncrementally(
                historyPanel.items,
                isRichText: isRichText,
                listMode: listMode.value,
                mutation: mutation
            )
        }
        historyListView.layoutSubtreeIfNeeded()
        PasteboardDiagnostics.log(
            "ui reload rows=\(current.items.count) search=\(current.isSearchResult) mode=\(listMode.value)"
        )
    }
    
    /// Reloads a row when favorite/password metadata changes without altering the item list.
    private func refreshHistoryItemDisplay(_ item: HistoryItem) {
        historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
        let visibleItems = itemsForActiveListMode(from: appState.history.items)
        guard let row = visibleItems.firstIndex(where: { $0.fsId == item.fsId }) else { return }
        historyListView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
        historyListView.reloadItem(row)
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

    func pasteSelectedPlainText() {
        guard let selected = historyListView.selected,
              selected >= 0, selected < historyPanel.items.count else { return }
        historyPanel.paste(item: historyPanel.items[selected], plainTextOnly: true)
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
    
    func close(reason: PanelCloseReason = .userAction) {
        isPreviewShowing = false
        appState.panelCloseReason = reason
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
        guard appState.isHistoryPanelShown.value else { return }
        AppActivation.activateFrontmostApplication()
        self.searchBar.becomeFirstResponder()
        if let editor = searchBar.currentEditor() as? NSTextView {
            editor.selectAll(nil)
        } else {
            searchBar.selectText(nil)
        }
    }

    // MARK: - Local key monitor (U04)

    private func configurePanelKeyMonitor() {
        panelKeyMonitor.isPanelKeyWindow = { [weak self] window in
            guard let self, let window else { return false }
            if window == self.view.window { return true }
            if let parent = window.sheetParent, parent == self.view.window { return true }
            return window.parent == self.view.window
        }
        panelKeyMonitor.focusZone = { [weak self] in
            self?.currentFocusZone() ?? .search
        }
        panelKeyMonitor.routerContext = { [weak self] in
            PanelKeyRouterContext(
                searchIsEmpty: self?.searchBar.stringValue.isEmpty ?? true,
                searchFieldOwnsEditingShortcuts: self?.searchBar.currentEditor() != nil,
                canUndoDelete: false
            )
        }
        panelKeyMonitor.onRoute = { [weak self] route, event in
            self?.handlePanelKeyRoute(route, event: event) ?? false
        }
    }

    private func currentFocusZone() -> FocusZone {
        if searchBar.currentEditor() != nil { return .search }
        return .list
    }

    @discardableResult
    private func handlePanelKeyRoute(_ route: PanelKeyRoute, event: NSEvent) -> Bool {
        // Esc walks the stack; ⌘W closes immediately (same registry id).
        if event.keyCode == 53, event.modifierFlags.isDisjoint(with: [.command, .control, .option, .shift]) {
            return performEscape()
        }
        switch route {
        case .passThrough:
            return false
        case .typeToSearch(let text):
            focusSearchBar()
            searchBar.stringValue += text
            scheduleSearch()
            return true
        case .command(let id):
            return performPanelCommand(id)
        }
    }

    private func performEscape() -> Bool {
        let state = EscapeStackState(
            overlayVisible: false,
            editorActive: false,
            editorHasChanges: false,
            editorDiscardArmed: false,
            passwordRevealed: false,
            multiSelectActive: false,
            searchIsEmpty: searchBar.stringValue.isEmpty,
            filtersActive: false
        )
        switch EscapeResolver.resolve(state) {
        case .clearSearch:
            searchBar.stringValue = ""
            applyListFilter()
            return true
        case .closePanel:
            close()
            return true
        default:
            close()
            return true
        }
    }

    @discardableResult
    private func performPanelCommand(_ id: PanelCommandID) -> Bool {
        switch id {
        case .paste: pasteSelected()
        case .pastePlainText: pasteSelectedPlainText()
        case .selectNext, .pageDown: goToNextItem()
        case .selectPrevious, .pageUp: goToPreviousItem()
        case .selectFirst:
            if !historyPanel.items.isEmpty { selected.accept(0) }
        case .selectLast:
            if !historyPanel.items.isEmpty { selected.accept(historyPanel.items.count - 1) }
        case .delete: deleteSelected()
        case .togglePreview: togglePreview()
        case .focusSearch: focusSearchBar()
        case .nextTab: switchToNextTab()
        case .previousTab: switchToPreviousTab()
        case .panelPositionLeft: appState.panelPosition.accept(.left)
        case .panelPositionRight: appState.panelPosition.accept(.right)
        case .panelPositionUp: appState.panelPosition.accept(.top)
        case .panelPositionDown: appState.panelPosition.accept(.bottom)
        case .quickPaste0: shortcutPressed(key: 0)
        case .quickPaste1: shortcutPressed(key: 1)
        case .quickPaste2: shortcutPressed(key: 2)
        case .quickPaste3: shortcutPressed(key: 3)
        case .quickPaste4: shortcutPressed(key: 4)
        case .quickPaste5: shortcutPressed(key: 5)
        case .quickPaste6: shortcutPressed(key: 6)
        case .quickPaste7: shortcutPressed(key: 7)
        case .quickPaste8: shortcutPressed(key: 8)
        case .quickPaste9: shortcutPressed(key: 9)
        case .openSettings:
            close()
            AppActivation.activateFrontmostApplication()
            NSApp.sendAction(#selector(Controller.showSettings), to: nil, from: nil)
        case .closePanel:
            close()
        default:
            break
        }
        return true
    }
    
    func scheduleSearch() {
        searchDebounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.runSearch()
        }
        searchDebounceWork = work
        let delay = Double(PanelHeaderPresenter.searchDebounceMs) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func runSearch() {
        let query = searchBar.stringValue
        let baseItems = itemsForActiveListMode(from: appState.history.items)
        if query.isEmpty {
            applyListFilter()
            return
        }

        let copiedAt = Dictionary(uniqueKeysWithValues: baseItems.map { ($0.fsId, $0.copiedAt) })
        let visibleIds = baseItems.map(\.fsId)
        let cache = appState.historyCache
        let applyResults: () -> Void = { [weak self] in
            self?.searchIndex.search(query: query, visibleIds: visibleIds, copiedAt: copiedAt) { ids in
                guard let self else { return }
                guard self.searchBar.stringValue == query else { return }
                let byId = Dictionary(uniqueKeysWithValues: baseItems.map { ($0.fsId, $0) })
                let filtered = ids.compactMap { byId[$0] }
                self.results.accept(Results(items: filtered, isSearchResult: true))
                self.syncHistoryTableToResults()
            }
        }
        // Lazy full build on first non-empty query; later updates are incremental (T22).
        if searchIndex.isBuilt {
            applyResults()
        } else {
            let sources = appState.history.items.map(SearchSource.init)
            searchIndex.replaceAll(sources: sources, cache: cache, completion: applyResults)
        }
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
        self.close(reason: .paste)
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
        if !appState.isHistoryLoaded {
            emptyListLabel?.stringValue = L10n.historyLoading
            emptyListLabel?.isHidden = false
            return
        }
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

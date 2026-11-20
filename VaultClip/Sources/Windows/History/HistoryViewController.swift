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
import Quartz
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

    var appState: State { injectedState ?? AppEnvironment.shared.state }
    var appSettings: Settings { (settingsProvider ?? { SettingsPersistence.current() })() }

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
    
    var emptyListLabel: NSTextField?

    private let panelKeyMonitor = PanelLocalKeyMonitor()
    let commandPaletteOverlay = CommandPaletteOverlayView()
    let cheatSheetOverlay = CheatSheetOverlayView()
    let embeddedPreview = EmbeddedPreviewView()
    let filterBar = PanelFilterBarView()
    let emptyStateHost = PanelEmptyStateHostView()
    var filterBarHeightConstraint: NSLayoutConstraint?
    var filterState = FilterState()
    private var filterBarVisible: Bool { appSettings.showsFilterBarPreference }
    var selectionModel = SelectionModel()
    let footerHintsLabel = NSTextField(labelWithString: "")
    let footerSeparator = NSBox()
    let toastView = PanelToastView()
    var previewConstraints: [NSLayoutConstraint] = []
    var listBottomToFooter: NSLayoutConstraint?
    var listTrailingToView: NSLayoutConstraint?
    var currentPreviewAxis: PreviewSplitAxis?
    var lastLayoutWidth: CGFloat = 0
    var quickLookURL: URL?
    let previewDebouncer = PreviewUpdateDebouncer(scheduler: PreviewDispatchScheduler())
    lazy var pendingDeletion = PendingDeletionQueue(
        scheduler: PendingDeletionDispatchScheduler()
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isRichText = appSettings.showsRichText
        
        configurePanelLayout()
        applyPanelChromeMetrics()
        styleHistoryChrome()
        installFilterBar()
        installEmbeddedPreview()
        installProgrammaticPanelLayout()
        installEmptyStateHost()
        installToast()
        installCommandPaletteOverlay()
        installCheatSheetOverlay()
        pendingDeletion.onCommit = { [weak self] ids in
            guard let self else { return }
            let toDelete = self.appState.history.items.filter { ids.contains($0.fsId) }
            for item in toDelete {
                _ = self.historyPanel.delete(item: item)
            }
            self.applyListFilter()
        }
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
                    self.syncEmbeddedPreviewVisibility()
                } else {
                    self.panelKeyMonitor.stop()
                    self.commandPaletteOverlay.dismiss()
                    self.cheatSheetOverlay.dismiss()
                    self.toastView.dismiss()
                    self.appState.previewHistoryItem.accept(nil)
                }
            })
            .disposed(by: disposeBag)
        
        searchBar.resignFirstResponder()
    }
    
    deinit {
        historyUnsubscribe?()
    }

    // MARK: - Quick Look (U21)

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        quickLookURL != nil
    }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = self
        panel.reloadData()
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
        quickLookURL = nil
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        syncEmbeddedPreviewVisibility()
        refreshHistoryListOnPanelOpen()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        alignHistoryListToScrollView()
        applyPreviewAxis()
        DispatchQueue.main.async { [weak self] in
            self?.alignHistoryListToScrollView()
            self?.refreshEmbeddedPreview()
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if abs(view.bounds.width - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = view.bounds.width
            applyPreviewAxis()
            refreshFooterHints()
        }
        guard appState.isHistoryPanelShown.value else { return }
        historyListView.syncColumnWidthToScrollView()
    }

    /// Clears stale search / height cache and reloads when the panel becomes visible.
    private func refreshHistoryListOnPanelOpen() {
        // Open policy (U20): History tab unless «reopen last tab», first (or second) row selected.
        if !appSettings.reopenLastTab, listMode.value != .history {
            listMode.accept(.history)
        }
        let baseItems = itemsForActiveListMode(from: appState.history.items)
        if !searchBar.stringValue.isEmpty, baseItems.count > 0, results.value.items.isEmpty {
            searchBar.stringValue = ""
        }
        updateFilterBarVisibility()
        applyListFilter()
        resetSelected(preferSecond: appSettings.selectSecondItem)
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
    
    func resetSelected(preferSecond: Bool = false) {
        let count = historyPanel.items.count
        if count > 0 {
            selected.accept(preferSecond && count > 1 ? 1 : 0)
        } else {
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
            showToast(L10n.countPinnedLimit(current: current, max: max))
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
        let filtered = applyTypeAndAppFilters(to: baseItems)
        // Do not rebuild a full-text engine here — SearchIndex updates incrementally / on demand (T22).
        let isFiltered = filterState.isActive || !searchBar.stringValue.isEmpty
        results.accept(Results(items: filtered, isSearchResult: isFiltered && filtered.count != baseItems.count))
        updateEmptyListLabel(for: listMode.value, visible: filtered.isEmpty)
        syncHistoryTableToResults(mutation: mutation)
        refreshFilterBarApps(from: baseItems)
        let visibleOrder = filtered.map(\.fsId)
        selectionModel.retainVisible(Set(visibleOrder), visibleOrder: visibleOrder)
        if selectionModel.isMulti {
            let indexes = IndexSet(selectionModel.orderedIds.compactMap { id in visibleOrder.firstIndex(of: id) })
            historyListView.selectItems(indexes)
        }
        refreshSelectionChrome()
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
        // Headers only for the chronological History tab; search/filter results are ranked.
        historyListView.groupsByDate = appSettings.groupHistoryByDate
            && listMode.value == .history
            && !current.isSearchResult

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
        // reloadData drops table selection while `selected` keeps its value (distinctUntilChanged
        // then never re-fires), so push the logical selection back into the table.
        if !selectionModel.isMulti {
            let count = historyPanel.items.count
            if let row = selected.value, row >= count {
                selected.accept(count > 0 ? count - 1 : nil)
            } else if selected.value == nil, count > 0 {
                selected.accept(0)
            }
            if let row = selected.value, row >= 0, row < count {
                historyListView.selectItem(row)
            }
        }
        // Same row index can now point at another item (filter/search), so always refresh.
        scheduleEmbeddedPreviewUpdate()
        refreshFooterHints()
        PasteboardDiagnostics.log(
            "ui reload rows=\(current.items.count) search=\(current.isSearchResult) mode=\(listMode.value)"
        )
    }
    
    /// Reloads a row when favorite/password metadata changes without altering the item list.
    private func refreshHistoryItemDisplay(_ item: HistoryItem) {
        historyListView.cellHeightsCache.removeCellHeight(forId: item.fsId)
        let visibleItems = itemsForActiveListMode(from: appState.history.items)
        guard let row = visibleItems.firstIndex(where: { $0.fsId == item.fsId }) else { return }
        if let tableRow = historyListView.row(forItemIndex: row) {
            historyListView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: tableRow))
        }
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
        if selectionModel.isMulti {
            multiPasteSelected(plainTextOnly: false)
            return
        }
        if let selected = self.historyListView.selected {
            paste(selected: selected)
        }
    }

    func pasteSelectedPlainText() {
        if selectionModel.isMulti {
            multiPasteSelected(plainTextOnly: true)
            return
        }
        guard let selected = historyListView.selected,
              selected >= 0, selected < historyPanel.items.count else { return }
        historyPanel.paste(item: historyPanel.items[selected], plainTextOnly: true)
    }
    
    func deleteSelected() {
        let rows: [Int]
        if selectionModel.isMulti {
            let order = historyPanel.items.map(\.fsId)
            let idToRow = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            rows = selectionModel.orderedIds.compactMap { idToRow[$0] }.sorted()
        } else if let row = historyListView.selected {
            rows = [row]
        } else {
            rows = []
        }
        guard !rows.isEmpty else { return }
        let ids = rows.map { historyPanel.items[$0].fsId }
        pendingDeletion.enqueue(itemIds: ids, originalIndexes: rows)
        // Soft-hide: filter pending ids out of the table until commit/undo.
        let hidden = pendingDeletion.hiddenItemIds
        let visible = results.value.items.filter { !hidden.contains($0.fsId) }
        results.accept(Results(items: visible, isSearchResult: results.value.isSearchResult))
        syncHistoryTableToResults(mutation: .reload)
        selectionModel.clear()
        if !visible.isEmpty {
            selected.accept(min(rows.first ?? 0, visible.count - 1))
        } else {
            selected.accept(nil)
        }
        refreshSelectionChrome()
        showToast(L10n.toastDeleted(ids.count), actionTitle: L10n.toastUndo) { [weak self] in
            self?.undoPendingDeletion()
        }
    }

    func undoPendingDeletion() {
        guard let batch = pendingDeletion.undoLast() else { return }
        applyListFilter()
        if let index = batch.originalIndexes.first {
            selected.accept(min(index, max(0, historyPanel.items.count - 1)))
        }
    }
    
    func switchToPreviousTab() {
        listMode.accept(listMode.value.previous())
    }
    
    func switchToNextTab() {
        listMode.accept(listMode.value.next())
    }
    
    func close(reason: PanelCloseReason = .userAction) {
        pendingDeletion.flushAll()
        embeddedPreview.endEditing()
        if appSettings.resetFiltersOnClose {
            clearFilters(resetSearch: true)
        }
        appState.panelCloseReason = reason
        appState.isHistoryPanelShown.accept(false)
        appState.previewHistoryItem.accept(nil)
        resetSelected()
    }

    func shortcutPressed(key: Int) {
        // ⌘1…⌘9 → items 1–9; ⌘0 → 10th (U20).
        guard let index = PanelNavigation.displayedIndex(
            forQuickPasteKey: key,
            visibleItemCount: historyPanel.items.count
        ) else { return }
        paste(selected: index)
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
                canUndoDelete: !(self?.pendingDeletion.batches.isEmpty ?? true)
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
        // Overlays own ↑/↓/⏎/Esc and their search field; nothing reaches the list underneath.
        for overlay in [commandPaletteOverlay, cheatSheetOverlay] as [PanelOverlayListView] where !overlay.isHidden {
            if overlay.handleKey(event) { return true }
            let mods = event.modifierFlags.intersection([.command, .control, .option])
            if mods == .command, let id = route.commandID, [.commandPalette, .cheatSheet, .closePanel].contains(id) {
                return performPanelCommand(id)
            }
            return false
        }
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
            overlayVisible: !commandPaletteOverlay.isHidden || !cheatSheetOverlay.isHidden,
            editorActive: false,
            editorHasChanges: false,
            editorDiscardArmed: false,
            passwordRevealed: false,
            multiSelectActive: selectionModel.isMulti,
            searchIsEmpty: searchBar.stringValue.isEmpty,
            filtersActive: filterState.isActive
        )
        switch EscapeResolver.resolve(state) {
        case .dismissOverlay:
            if !commandPaletteOverlay.isHidden {
                commandPaletteOverlay.dismiss()
            } else {
                cheatSheetOverlay.dismiss()
            }
            return true
        case .collapseMultiSelect:
            collapseMultiSelectToAnchor()
            return true
        case .clearSearch:
            searchBar.stringValue = ""
            applyListFilter()
            return true
        case .clearFilters:
            clearFilters(resetSearch: false)
            return true
        case .closePanel:
            close()
            return true
        default:
            close()
            return true
        }
    }

    private func installCommandPaletteOverlay() {
        installOverlay(commandPaletteOverlay, maxHeight: 360)
        commandPaletteOverlay.onSelect = { [weak self] id in
            _ = self?.performPanelCommand(id)
        }
        commandPaletteOverlay.onDismiss = { [weak self] in self?.restorePanelFocus() }
    }

    /// Overlays sit under the search field, above tabs/list, and never exceed the panel.
    private func installOverlay(_ overlay: PanelOverlayListView, maxHeight: CGFloat) {
        view.addSubview(overlay)
        let width = overlay.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20)
        width.priority = .defaultHigh
        let height = overlay.heightAnchor.constraint(equalToConstant: maxHeight)
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlay.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
            overlay.widthAnchor.constraint(lessThanOrEqualToConstant: 460),
            overlay.bottomAnchor.constraint(lessThanOrEqualTo: footerSeparator.topAnchor, constant: -8),
            width,
            height
        ])
    }

    private func restorePanelFocus() {
        guard appState.isHistoryPanelShown.value else { return }
        view.window?.makeFirstResponder(searchBar)
    }

    private func showCommandPalette() {
        cheatSheetOverlay.dismiss()
        let ctx = PanelCommandContext(
            hasSelection: historyListView.selected != nil,
            selectionCount: max(selectionModel.count, historyListView.selected == nil ? 0 : 1),
            searchIsEmpty: searchBar.stringValue.isEmpty
        )
        commandPaletteOverlay.present(context: ctx)
    }

    private func installCheatSheetOverlay() {
        installOverlay(cheatSheetOverlay, maxHeight: 420)
        cheatSheetOverlay.onDismiss = { [weak self] in self?.restorePanelFocus() }
    }

    private func showCheatSheet() {
        commandPaletteOverlay.dismiss()
        if cheatSheetOverlay.isHidden {
            cheatSheetOverlay.present()
        } else {
            cheatSheetOverlay.dismiss()
        }
    }

    @discardableResult
    func performPanelCommand(_ id: PanelCommandID) -> Bool {
        switch id {
        case .paste:
            if embeddedPreview.isEditing { pasteEditedPreviewText() } else { pasteSelected() }
        case .pastePlainText: pasteSelectedPlainText()
        case .selectNext: goToNextItem()
        case .selectPrevious: goToPreviousItem()
        case .pageDown: movePage(direction: 1)
        case .pageUp: movePage(direction: -1)
        case .copy: copySelected()
        case .toggleFavorite: toggleFavoriteSelected()
        case .openLinkOrFile: openSelectedLinkOrFile()
        case .revealInFinder: revealSelectedInFinder()
        case .quickLook: toggleQuickLook()
        case .editBeforePaste: beginEditBeforePaste()
        case .pasteEdit: pasteEditedPreviewText()
        case .saveEdit: pasteEditedPreviewText()
        case .textSizeIncrease: changeTextSize(by: 1)
        case .textSizeDecrease: changeTextSize(by: -1)
        case .togglePanel: close()
        case .selectFirst:
            if !historyPanel.items.isEmpty { selected.accept(0) }
        case .selectLast:
            if !historyPanel.items.isEmpty { selected.accept(historyPanel.items.count - 1) }
        case .extendSelectionUp:
            extendSelection(direction: -1)
        case .extendSelectionDown:
            extendSelection(direction: 1)
        case .selectAll:
            selectAllVisible()
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
            // Controller is not in the responder chain, so a nil-target action never arrived.
            AppEnvironment.shared.controller?.showSettings()
        case .commandPalette:
            if commandPaletteOverlay.isHidden {
                showCommandPalette()
            } else {
                commandPaletteOverlay.dismiss()
            }
        case .undoDelete:
            undoPendingDeletion()
        case .filterTypeAll:
            setTypeFilter(.all)
        case .filterTypeText:
            setTypeFilter(.text)
        case .filterTypeLinks:
            setTypeFilter(.link)
        case .filterTypeImages:
            setTypeFilter(.image)
        case .filterTypeFiles:
            setTypeFilter(.file)
        case .filterTypeColors:
            setTypeFilter(.color)
        case .filterApp:
            showAppFilterMenu()
        case .clearFilters:
            clearFilters(resetSearch: true)
        case .cheatSheet:
            showCheatSheet()
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
        promoteCompletedSearchTokens()
        let query = searchBar.stringValue
        let tabItems = itemsForActiveListMode(from: appState.history.items)
        let baseItems = applyTypeAndAppFilters(to: tabItems)
        refreshFilterBarApps(from: tabItems)
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

    private func installFilterBar() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterBar)
        filterBar.onTypeChange = { [weak self] type in
            self?.setTypeFilter(type)
        }
        filterBar.onAppChange = { [weak self] query in
            guard let self else { return }
            self.filterState.appQuery = query
            self.filterBar.apply(self.filterState)
            self.scheduleSearch()
        }
        listMode.subscribe(onNext: { [weak self] _ in
            self?.updateFilterBarVisibility()
            self?.scheduleSearch()
        }).disposed(by: disposeBag)
    }

    func setTypeFilter(_ type: TypeFilter) {
        filterState.type = type
        filterBar.apply(filterState)
        scheduleSearch()
    }

    func clearFilters(resetSearch: Bool) {
        filterState = FilterState()
        filterBar.apply(filterState)
        if resetSearch {
            searchBar.stringValue = ""
        }
        applyListFilter()
    }

    private func showAppFilterMenu() {
        updateFilterBarVisibility()
        // Focus app popup so ⌥⌘A opens the source list (U14).
        filterBar.window?.makeFirstResponder(filterBar)
    }

    private func promoteCompletedSearchTokens() {
        let raw = searchBar.stringValue
        let parsed = SearchTokenParser.parse(raw)
        var changed = false
        if parsed.filter.type != .all {
            filterState.type = parsed.filter.type
            changed = true
        }
        if let app = parsed.filter.appQuery {
            filterState.appQuery = app
            changed = true
        }
        if parsed.remainingQuery != raw {
            searchBar.stringValue = parsed.remainingQuery
            changed = true
        }
        if changed {
            filterBar.apply(filterState)
        }
    }

    private func applyTypeAndAppFilters(to items: [HistoryItem]) -> [HistoryItem] {
        guard filterState.isActive, listMode.value != .passwords else { return items }
        return items.filter { item in
            filterState.matches(
                kind: itemKind(for: item),
                sourceBundleId: item.sourceBundleId,
                appDisplayName: SourceAppDisplayName.name(forBundleId: item.sourceBundleId)
            )
        }
    }

    func itemKind(for item: HistoryItem) -> ItemKind {
        HistoryItemSummaryBuilder.shared.kind(for: item)
    }

    private func refreshFilterBarApps(from items: [HistoryItem]) {
        let pairs = items.map {
            (bundleId: $0.sourceBundleId, displayName: SourceAppDisplayName.name(forBundleId: $0.sourceBundleId))
        }
        filterBar.reloadApps(from: pairs, selectedQuery: filterState.appQuery)
        filterBar.apply(filterState)
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
    
    func paste(selected: Int) {
        self.close(reason: .paste)
        historyPanel.paste(displayedIndex: selected)
    }
    
    func syncSelectionModelFromTable() {
        let items = historyPanel.items
        let indexes = historyListView.selectedItemIndexes.sorted()
        let ids = indexes.compactMap { idx -> UUID? in
            guard items.indices.contains(idx) else { return nil }
            return items[idx].fsId
        }
        let anchor = selectionModel.anchorId.flatMap { ids.contains($0) ? $0 : nil } ?? ids.first
        selectionModel.replace(ordered: ids, anchor: anchor)
    }

    func refreshSelectionChrome() {
        itemCountLabel.stringValue = countLabelText(for: results.value)
        refreshFooterHints()
    }

    private func collapseMultiSelectToAnchor() {
        let anchor = selectionModel.anchorId ?? selectionModel.orderedIds.first
        selectionModel.clear()
        if let anchor, let row = historyPanel.items.firstIndex(where: { $0.fsId == anchor }) {
            selectionModel.selectSingle(anchor)
            historyListView.selectItem(row)
            selected.accept(row)
        } else {
            historyListView.deselectAll(nil)
            selected.accept(nil)
        }
        refreshSelectionChrome()
    }

    private func selectAllVisible() {
        let order = historyPanel.items.map(\.fsId)
        selectionModel.selectAll(visibleOrder: order)
        let indexes = IndexSet(integersIn: 0..<historyPanel.items.count)
        historyListView.selectItems(indexes)
        if !historyPanel.items.isEmpty {
            selected.accept(0)
        }
        refreshSelectionChrome()
    }

    private func extendSelection(direction: Int) {
        let order = historyPanel.items.map(\.fsId)
        guard !order.isEmpty else { return }
        // Grow from the moving cursor; the anchor stays where the range started.
        let cursor = min(max(selected.value ?? 0, 0), order.count - 1)
        if selectionModel.anchorId.map({ !order.contains($0) }) ?? true || selectionModel.count <= 1 {
            selectionModel.selectSingle(order[cursor])
        }
        let next = min(max(cursor + direction, 0), order.count - 1)
        selectionModel.selectRange(to: order[next], visibleOrder: order)
        let selectedIndexes = IndexSet(selectionModel.orderedIds.compactMap { id in order.firstIndex(of: id) })
        historyListView.selectItems(selectedIndexes)
        selected.accept(next)
        refreshSelectionChrome()
    }

    private func multiPasteSelected(plainTextOnly: Bool) {
        let items = selectionModel.orderedIds.compactMap { id in historyPanel.items.first(where: { $0.fsId == id }) }
        guard !items.isEmpty else { return }
        let separator = MultiPasteSeparator(rawValue: appSettings.multiPasteSeparator) ?? .newline
        let composeItems = items.map { item in
            MultiPasteComposer.Item(
                kind: itemKind(for: item),
                text: item.getPlainString(),
                isPassword: item.isPassword
            )
        }
        let result = MultiPasteComposer.compose(
            items: composeItems,
            separator: separator,
            reverse: false
        )
        close(reason: .paste)
        switch result.payload {
        case .joinedText(let text):
            let body = plainTextOnly ? text : text
            historyPanel.multiPasteJoined(body, items: items)
        case .discreteItems:
            historyPanel.multiPasteDiscrete(items)
        case .none:
            break
        }
    }

    private func countLabelText(for results: Results) -> String {
        if selectionModel.isMulti {
            return PanelStatusBarPresenter.counter(for: PanelStatusBarInput(
                totalCount: results.items.count,
                visibleCount: results.items.count,
                isSearch: results.isSearchResult,
                selectedCount: selectionModel.count,
                isLoading: false,
                hintContext: .multiSelect(count: selectionModel.count),
                availableWidth: 400,
                showKeyHints: false,
                locale: .current
            ))
        }
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
        label.font = NSFont.systemFont(ofSize: PanelChrome.Typography.chromeSize)
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
                constant: PanelChrome.Metrics.scaled(20)
            ),
            label.trailingAnchor.constraint(
                lessThanOrEqualTo: scrollView.trailingAnchor,
                constant: -PanelChrome.Metrics.scaled(20)
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
        emptyListLabel?.isHidden = true
        let isSearch = results.value.isSearchResult || filterState.isActive || !searchBar.stringValue.isEmpty
        let kind: PanelEmptyKind?
        if !appState.isHistoryLoaded {
            kind = nil
        } else if visible, isSearch {
            kind = .noResults(query: searchBar.stringValue)
        } else if visible {
            switch mode {
            case .history: kind = .history
            case .favorites: kind = .favorites
            case .passwords: kind = .passwords
            }
        } else {
            kind = nil
        }
        let model = PanelEmptyStatePresenter.present(
            kind: kind,
            isLoading: !appState.isHistoryLoaded,
            isCapturePaused: appSettings.isCapturePaused,
            filtersActive: filterState.isActive,
            otherTabHitCount: nil,
            otherTab: nil
        )
        emptyStateHost.onPrimary = { [weak self] in
            guard let self else { return }
            if self.filterState.isActive || !self.searchBar.stringValue.isEmpty {
                self.clearFilters(resetSearch: true)
            } else if self.appSettings.isCapturePaused {
                SettingsPersistence.apply { $0.isCapturePaused = false }
            }
        }
        emptyStateHost.apply(model)
    }

    private func installEmptyStateHost() {
        view.addSubview(emptyStateHost)
        guard let scrollView = historyListView.enclosingScrollView else { return }
        NSLayoutConstraint.activate([
            emptyStateHost.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            emptyStateHost.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            emptyStateHost.topAnchor.constraint(equalTo: scrollView.topAnchor),
            emptyStateHost.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
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

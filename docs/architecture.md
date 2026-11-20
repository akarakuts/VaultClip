# VaultClip architecture (macOS)

**Version:** 2.3.1 (ui-redesign branch)  
**Minimum macOS:** 14.0  
**Contact:** [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Overview

VaultClip is a menu-bar clipboard manager for macOS 14+. The app monitors `NSPasteboard`, persists encrypted history on disk, and exposes a floating history panel with search, favorites, and password vault tabs.

```
AppDelegate
  └── AppEnvironment.bootstrap()
        ├── Settings (persisted via SettingsPersistence)
        ├── State (Rx relays, History, PasteboardMonitor)
        └── Controller.attachController()
              ├── AppRouting (toggle panel, welcome/help windows)
              ├── HistoryWindowController → HistoryViewController.configure(state:settings:)
              └── status item menu
```

## Composition root

`AppEnvironment` is the **single entry point** after launch:

| Accessor | Use |
|----------|-----|
| `AppEnvironment.shared.state` | History, pasteboard monitor, panel relays |
| `AppEnvironment.shared.settings` | User preferences |
| `AppEnvironment.shared.routing` | `AppRouting` — panel toggle, welcome/help (requires `attachController`) |

`SettingsPersistence.apply { … }` / `SettingsPersistence.current()` is the only settings write/read path for live values (used by Rx binds and settings UI).

Legacy `State.main` / `Controller.main` / `Settings.main` remain as thin forwarders for tests and Yippy-era call sites; **new code must use `AppEnvironment`**.

## Layers

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Composition** | `AppEnvironment`, `AppRouting`, `SettingsPersistence` | Bootstrap, navigation, settings I/O |
| **App shell** | `AppDelegate`, `Controller` | Status item, windows, menu |
| **State** | `State.swift` | Shared reactive state (`BehaviorRelay`) |
| **Domain** | `History`, `HistoryItem`, `SearchIndex`, `HistoryPasteboardPolicy` | Clipboard rules, contentDigest dedup/promote, favorites/passwords, ranked search |
| **Persistence** | `HistoryFileManager`, `HistoryFileManaging`, `SymmetricKeyStore`, `KeyResolver` | Encrypted files under Application Support |
| **Security** | `SecureStorageHelper`, `AESGCMDataEncryptor`, `EncryptionKeyBootstrap`, `PasswordAccessGate` | Path validation, chmod, key selection, LA |
| **Platform** | `PasteboardMonitor`, `PasteboardChangeTracking`, `LaunchAtLoginHelper`, `AppActivation` | Pasteboard polling, login items, `flock` |
| **UI** | `HistoryViewController`, `HistoryPanel`, settings tabs | Panel layout, tabs, table, search (injected `state` / settings provider) |

## Dependency injection

- `HistoryViewController.configure(state:settings:)` — `settings` is `() -> Settings` (`SettingsPersistence.current`), not a stale struct snapshot
- `PreviewWindowController.create(state:)` — binds `showsRichText` from the injected `State`
- Settings tabs receive `State` via `SettingsTabViewController.configure(state:)` from `Controller.showSettings`
- `History.init(historyFM:cache:…)` — `HistoryFileManaging` protocol (tests use mocks)
- `HistoryPasteboardPolicy` — pure denylist / concealed-type rules (unit-tested)

## Threading and history lifecycle

- **Main-thread invariant:** `History` is created and mutated only on the main queue (`dispatchPrecondition` in DEBUG). `HistoryItem` is a reference type: the `[HistoryItem]` arrays passed to persistence are shared references, not value snapshots. `HistoryItem._unsavedData` is guarded by an `NSLock`; `startCaching` / `stopCaching` run on main (not on the file-manager queue).
- **SearchIndex** builds/refreshes off the main queue; UI applies results on main. Fuse was removed — matching is folded substring + ranking.
- **Async launch load:** `State` starts with an empty `History`; `History.loadAsync` / `HistoryFileManager.loadHistory` return `[HistoryItem]` from the file-manager queue and `replaceLoaded` installs them on main (`State.isHistoryLoaded` gates the "Loading history…" empty state). The pasteboard monitor keeps its change gate closed until `historyReady(liveChangeCount:)` replays anything copied during the load. `UITesting.isRunning` keeps the deterministic synchronous path.
- **Coalesced order writes:** inserts/moves of `order.xml` are batched inside `HistoryFileManager` (~1 s window, flushed on the next scheduled tick or immediately for deletes/clear). `applicationWillTerminate` calls `flushHistoryOrderSync(timeout: 1.5)` so a quit never loses the visible order. A crash inside the window leaves a stale order at worst — orphan item directories are recovered on next load, so no data loss.
- **Self-write marking:** `HistoryPanel.lastSelfWriteChangeCount` lets `History` skip re-recording the app's own pasteboard writes.
- **contentDigest:** SHA-256 of filtered payload types; duplicates are promoted to index 0 instead of inserting a second row.

## Storage identity and quarantine

- Release and Beta use distinct bundle ids / Application Support roots so histories never mix.
- Ciphertext that no candidate key can open is moved to a quarantine area rather than deleted, so restoring the correct key can recover items.
- Ad-hoc builds store the AES key in `.history-encryption-key` beside the data (weaker than Keychain).

## Diagnostics and logging

- Error/warning logs (`error.log`, `warning.log`) are chmod **0600** at launch and rotate above ~2 MB (`LogStorage`).
- Pasteboard diagnostics are **opt-in only**: launch the app with `--pasteboard-diagnostics` to write change counts and metadata (never clipboard contents) to `pasteboard-debug.log`; rotating/pruning applies while enabled.

## On-disk layout

```
~/Library/Application Support/com.karakuts.VaultClip/
├── history/
│   ├── order.xml          # UUID order (encrypted VC1)
│   └── <UUID>/            # per-item directory
│       ├── favorite
│       ├── password
│       ├── copiedAt
│       ├── contentDigest  # optional dedup fingerprint
│       └── <mime-encoded-files>
├── instance.lock          # single-instance flock
└── .history-encryption-key  # fallback key (Keychain preferred)
```

## Error model

`ClipErrorCode` provides stable `NSError` codes (1xxx history, 2xxx UI, 3xxx cache). Use `ClipError(.historyItemSaveFailed, localizedDescription: "...")` instead of ad-hoc `code: 0`.

## Testing

- **Unit:** `VaultClipTests` — **219** tests (scheme `VaultClip XCTest`)
- **Isolation:** the test host points `Constants.urls.appSupport` at a temporary directory (`StorageRoot` / `VaultClipTestSupport`); production Application Support is never used
- **Test host:** `VaultClipTestSupport` restores `AppEnvironment` after tests that replace singletons
- **UI:** `VaultClipUITests` — manual / local only (menu-bar host hangs on headless CI); Release strips UI-testing strings
- **CI:** `./scripts/run-unit-tests.sh`, `./scripts/check-coverage.sh`, SwiftLint with `.swiftlint-baseline.yml`, dedicated TSan job
- **Coverage gate:** `check-coverage.sh` enforces the **minimum** per-file line coverage across the core `Security`/`History` files including `KeyResolver.swift` (default ≥55%, override with `VAULTCLIP_COVERAGE_THRESHOLD`). Structurally untestable files (migration bootstrap, alert UI, mock-only shims) are excluded with reasons listed in the script header.

## Code navigation

- Interactive graph: `graphify-out/graph.html` (`graphify update .`)
- Linux port plan: [docs/linux-port-plan.md](linux-port-plan.md)

## Roadmap to portable core

RxSwift + AppKit in `History`/`State` block a true 10/10 platform split. Next step: extract pasteboard + history rules into a Rust/Swift shared core per `linux-port-plan.md`.

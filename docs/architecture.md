# VaultClip architecture (macOS)

**Version:** 2.3.1  
**Contact:** [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Overview

VaultClip is a menu-bar clipboard manager for macOS. The app monitors `NSPasteboard`, persists encrypted history on disk, and exposes a floating history panel with search, favorites, and password vault tabs.

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

`SettingsPersistence.apply { … }` is the only settings write path (used by Rx binds and settings UI).

Legacy `State.main` / `Controller.main` / `Settings.main` remain as thin forwarders for tests and Yippy-era call sites; **new code must use `AppEnvironment`**.

## Layers

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Composition** | `AppEnvironment`, `AppRouting`, `SettingsPersistence` | Bootstrap, navigation, settings I/O |
| **App shell** | `AppDelegate`, `Controller` | Status item, windows, menu |
| **State** | `State.swift` | Shared reactive state (`BehaviorRelay`) |
| **Domain** | `History`, `HistoryItem`, `SearchEngine`, `HistoryPasteboardPolicy` | Clipboard rules, dedup, favorites/passwords, fuzzy search |
| **Persistence** | `HistoryFileManager`, `HistoryFileManaging`, `SymmetricKeyStore` | Encrypted files under Application Support |
| **Security** | `SecureStorageHelper`, `AESGCMDataEncryptor` | Path validation, chmod, Keychain key |
| **Platform** | `PasteboardMonitor`, `PasteboardChangeTracking`, `LaunchAtLoginHelper` | Pasteboard polling, login items, `flock` |
| **UI** | `HistoryViewController`, `HistoryPanel` | Panel layout, tabs, table, search (injected `state`/`settings`) |

## Dependency injection

- `HistoryViewController.configure(state:settings:)` — wired from `Controller.createHistoryWindowController`
- `History.init(historyFM:cache:…)` — `HistoryFileManaging` protocol (tests use mocks)
- `HistoryPasteboardPolicy` — pure denylist / concealed-type rules (unit-tested)

## Threading and history lifecycle

- **Main-thread invariant:** `History._items` is mutated on the main queue only; file I/O is handed to `HistoryFileManager`'s serial queue. Async work returning to `History` (load completion, prune) hops back via `DispatchQueue.main`.
- **Async launch load:** `State` starts with an empty `History`; `History.loadAsync` scans on the file-manager queue and publishes on main (`State.isHistoryLoaded` gates the "Loading history…" empty state). The pasteboard monitor keeps its change gate closed until `historyReady(liveChangeCount:)` replays anything copied during the load — the launch sync then feeds the backlog. `UITesting.isRunning` keeps the deterministic synchronous path.
- **Coalesced order writes:** inserts/moves of `order.xml` are batched inside `HistoryFileManager` (~1 s window, flushed on the next scheduled tick or immediately for deletes/reduce/clear). `applicationWillTerminate` calls `flushHistoryOrderSync(timeout: 1.5)` so a quit never loses the visible order. A crash inside the window leaves a stale order at worst — orphan item directories are recovered on next load, so no data loss.
- **Self-write marking:** `HistoryPanel.lastSelfWriteChangeCount` lets `History` skip re-recording the app's own `writeObjects` (dedup loop guard).

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
│       └── <mime-encoded-files>
├── instance.lock          # single-instance flock
└── .history-encryption-key  # fallback key (Keychain preferred)
```

## Error model

`ClipErrorCode` provides stable `NSError` codes (1xxx history, 2xxx UI, 3xxx cache). Use `ClipError(.historyItemSaveFailed, localizedDescription: "...")` instead of ad-hoc `code: 0`.

## Testing

- **Unit:** `VaultClipTests` — 141 tests (scheme `VaultClip XCTest`)
- **Test host:** `VaultClipTestSupport` restores `AppEnvironment` after tests that replace singletons
- **UI:** `VaultClipUITests` — manual / local only (menu-bar host hangs on headless CI)
- **CI:** `./scripts/run-unit-tests.sh`, `./scripts/check-coverage.sh`, SwiftLint with `.swiftlint-baseline.yml`
- **Coverage gate:** `check-coverage.sh` enforces the **minimum** per-file line coverage across the core `Security`/`History` files (default ≥55%, override with `VAULTCLIP_COVERAGE_THRESHOLD`). Structurally untestable files (migration bootstrap, alert UI, mock-only shims) are excluded with reasons listed in the script header.

## Code navigation

- Interactive graph: `graphify-out/graph.html` (`graphify update .`)
- Linux port plan: [docs/linux-port-plan.md](linux-port-plan.md)

## Roadmap to portable core

RxSwift + AppKit in `History`/`State` block a true 10/10 platform split. Next step: extract pasteboard + history rules into a Rust/Swift shared core per `linux-port-plan.md`.

# Changelog

All notable changes to **VaultClip** are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions use [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

When you ship a release, move items from **Unreleased** into a dated version section.

---

## [Unreleased]

### Added

- **LogStorage** — hardens `error.log`/`warning.log` to mode **0600** at launch and rotates them above ~2 MB (tail kept); the opt-in diagnostics log rotates only while enabled.
- **Opt-in pasteboard diagnostics** — launch with `--pasteboard-diagnostics` to write change counts and metadata (never clipboard contents) to `pasteboard-debug.log`.
- **Reversible percent-encoding for pasteboard-type file names** (`SecureStorageHelper.sanitizedPasteboardFileName` / `pasteboardType(fromStoredFileName:)`) — `%`, `/`, `:` and dot-only names are encoded; legacy stored names keep decoding to the same types.
- **Encryption probe at launch** (`HistoryEncryptionProbe`) — detects payloads the current key cannot decrypt and routes the user through the key-reset flow instead of silently losing history.
- **Async history load** — `History.loadAsync` / `State.isHistoryLoaded`; the panel opens instantly and shows a localized "Loading history…" state while the encrypted scan runs on the file-manager queue.
- **Pasteboard gate for the launch window** — `PasteboardMonitor.historyReady(liveChangeCount:)` replays anything copied while history was loading; nothing made during startup is missed.
- **Coalesced `order.xml` writes** — inserts/moves batch into a single disk write (~1 s window); deletes, reduce and clear flush immediately; `applicationWillTerminate` drains synchronously (1.5 s timeout). Crash staleness is bounded by orphan-directory recovery on next load.
- **Per-item `pastesRichText` flag** — paste/move attach RTF/HTML variants according to the setting captured at copy time.
- Unit tests grew from 99 to **141** — log hardening, storage helper encode/decode, AES-GCM contract, `DataFileManager` encryption, encryption probe, async load semantics, order coalescing, pasteboard gate, settings shared install.

### Changed

- **Coverage gate** (`scripts/check-coverage.sh`) now enforces the **minimum** per-file line coverage across core Security/History files (threshold and `VAULTCLIP_COVERAGE_THRESHOLD` unchanged at 55%); structurally untestable files are excluded with reasons in the script header.
- **CI** installs pinned SwiftLint **0.65.1** from the portable release asset instead of `brew install` (baseline parity with local linting) and checks `MARKETING_VERSION` consistency across build configurations.
- **Fuse** SPM requirement pinned to `exactVersion` 1.4.0, matching HotKey and RxSwift pins.
- `Settings.bootstrapOverride` replaced with the installed `Settings.shared` slot; `SettingsPersistence` reads it when no `AppEnvironment` is bootstrapped (production code still goes through `AppEnvironment`).
- Foreground activation unified in `AppActivation` — `NSRunningApplication.activate()` on macOS 14+, legacy `ignoringOtherApps` API below.
- History metadata files written with atomic options; failing item deletes no longer abort the whole batch (per-item error logging, aggregate result preserved).
- Pasteboard polling backs off 0.05 s → 0.25 s after 10 quiet ticks and resets on activity or app activation (lower idle power draw).
- Removed dead paths: legacy `getThumbnailImage()`, unused `comparedTo` parameter in pasteboard payload extraction; color payloads now use secure keyed-unarchiving with legacy fallback.
- Custom drag-and-drop pasteboard type renamed to `com.karakuts.VaultClip.history-item-id` (app-internal, in-app drops only).
- `docs/architecture.md`, `README.md`, `README.ru.md` — threading/lifecycle invariants, diagnostics, storage naming, coverage gate, and test-count documentation.

### Fixed

- Panel actions (`paste`, `move to top`, `delete`) no longer re-record the app's own clipboard writes (self-change-count guard).
- Password items no longer occupy the string cache (cache invariant matches displayed history).
- Clear-history / menu routing reaches the visible `HistoryViewController` for delete-selected instead of a stale reference; preview shows a caution icon when an image cannot be decoded.
- Empty-list label distinguishes "still loading" from "nothing copied yet".

---

## [2.3.1] — 2026-06-19

### Added

- **SettingsPersistence** — single write path for settings (via `AppEnvironment` or test override).
- **AppRouting** — navigation protocol (`togglePopover`, welcome/help windows) decoupled from `Controller.main`.
- **PasteboardChangeTracking** — minimal pasteboard protocol for monitors and mocks.
- **VaultClipTestSupport** — restores production `AppEnvironment` after tests that replace singletons.
- **SettingsPersistenceTests** — unit tests for settings I/O without test-host crashes.
- **SwiftLint baseline** (`.swiftlint-baseline.yml`) — CI blocks new lint violations.

### Changed

- **AppEnvironment.routing** — production code uses composition root instead of `State.main` / `Controller.main` / `Settings.main`.
- **HistoryViewController** — `configure(state:settings:)` injection from `Controller`; `appState` accessor.
- **Settings** / **State** Rx binds write through `SettingsPersistence.apply`.
- **check-coverage.sh** — fixed xccov parsing (Security/History peak thresholds).
- **README.md** / **README.ru.md** — CI test scripts, developer docs, `instance.lock` in data paths.
- Unit test count: **99** (stable full-suite runs).

### Fixed

- **HistoryFileManagerTests** — mock filesystem no longer falls through to real paths on clean CI runners.

---

## [2.2.0] — 2026-06-19

### Added

- **ClipErrorCode** — stable NSError codes for history, UI, and cache errors.
- **HistoryPasteboardPolicy** — centralized password-manager denylist and pasteboard type filtering.
- **HistoryPanelChromeConfigurator** — extracted history panel layout and typography.
- **docs/architecture.md** — macOS architecture overview.
- **SwiftLint** configuration and CI lint step.
- **CI unit tests** — `scripts/run-unit-tests.sh` runs the full `VaultClipTests` suite on every push.
- Unit tests for error codes, pasteboard policy, and single-instance lock path.

### Changed

- **AppEnvironment** composition root replaces implicit singleton construction; `State`/`Controller`/`Settings` forward through bootstrap.
- **HistoryFileManaging** protocol abstracts persistence for `History`.
- CI **coverage gate** (`scripts/check-coverage.sh`, threshold 55%) for Security + History modules.
- **HistoryViewController** split: table/tab delegates moved to `HistoryViewController+Delegates.swift`.
- **HistoryFileManager** and related call sites use typed `ClipErrorCode` instead of `code: 0`.

---

## [2.1.2] — 2026-06-17

### Fixed

- **Launch at login** no longer quits the running app when the menu item is turned on. macOS used to spawn a second instance via the legacy login-items API; duplicates are now dismissed (`SingleInstanceGuard`), macOS 13+ uses `SMAppService`, and older systems register a hidden login item.

### Added

- **CHANGELOG.md** — version history; linked from `README.md` and `README.ru.md`.

---

## [2.1.1] — 2026-06-17

[Release](https://github.com/akarakuts/VaultClip/releases/tag/v2.1.1)

### Changed

- Replaced **CocoaPods** with **Swift Package Manager** (RxSwift 5.0.0, HotKey, Fuse).
- Vendored **Default** (UserDefaults Codable helpers) and **LoginServiceKit** into the app target.
- Removed the committed `Pods/` tree; open `VaultClip.xcodeproj` (no `pod install`).
- CI and `build-dmg.sh` build via `-project VaultClip.xcodeproj`.

### Added

- `Package.resolved` pins for SPM dependencies.

---

## [2.0.2] and earlier

Release **2.0.2** was the last tag before the repository history was reset to a single root commit (June 2026). Earlier work — AES-GCM encryption, Favorites and Passwords tabs, password-manager filtering, localization, Yippy fork lineage — lives in that snapshot and in forks of [Yippy](https://github.com/mattDavo/Yippy).

For tags and binaries from before the history reset, see [GitHub Releases](https://github.com/akarakuts/VaultClip/releases) (if retained) or build from the pre-reset commit via `git reflog` on a machine that still has it.

---

## Maintenance

Update this file **together with** user-visible changes in `README.md` / `README.ru.md` (features, install steps, security, shortcuts). README stays the product guide; **CHANGELOG** is the version-by-version delta.

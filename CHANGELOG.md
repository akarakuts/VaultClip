# Changelog

All notable changes to **VaultClip** are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions use [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

When you ship a release, move items from **Unreleased** into a dated version section.

---

## [Unreleased]

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

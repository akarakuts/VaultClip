# VaultClip

[![Release](https://img.shields.io/github/v/release/akarakuts/VaultClip)](https://github.com/akarakuts/VaultClip/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15%2B-000000?logo=apple)](https://github.com/akarakuts/VaultClip)

macOS clipboard manager with on-disk encrypted history, Favorites and Passwords tabs, and filtering of copies from password managers.

Open-source fork of [Yippy](https://github.com/mattDavo/Yippy) by Matthew Davidson. The original idea and UX are preserved; this fork adds stronger security, up-to-date toolchains, and the **VaultClip** rebrand.

**Repository:** [github.com/akarakuts/VaultClip](https://github.com/akarakuts/VaultClip) · **Русский:** [README.ru.md](README.ru.md)

![screenshot](images/screenshot.jpg)

## Features

### Clipboard history

- **Background monitoring** of the system pasteboard: every new copy (except filtered sources) is saved to local history.
- **Up to 5000 items** in the in-memory model; settings can cap the working set (50–1500).
- **Supported content types:**
  - plain text, RTF, and HTML;
  - URLs and links;
  - colors (swatch in the list);
  - raster images (TIFF, PNG, etc.);
  - PDF (thumbnail and label);
  - files with Finder icon or preview thumbnail.
- **Deduplication** — repeating the same content within the last 20 items does not create a duplicate entry.
- **Source app icon** on each row (bundle id of the copying application).
- **Copy timestamp** for items without a readable text representation.

### History / Favorites / Passwords tabs

The history panel has three icon tabs:

| Tab | Purpose |
|-----|---------|
| **History** | Full timeline (favorites and saved passwords are hidden from this stream). |
| **Favorites** | Pinned items; kept when clearing ordinary history and protected from pruning like regular entries. |
| **Passwords** | Explicitly saved passwords with an optional comment (site, login, note). |

Favorites and saving to Passwords are available **only from the context menu** (right-click on a row):

- add / remove favorite;
- save to passwords (with comment prompt);
- remove from passwords;
- edit password comment;
- delete item.

### Search and preview

- **Inline search** (⌘\\ focuses the search field): fuzzy matching over item text.
- For **saved passwords** outside the Passwords tab, search runs **on the comment only**, not the secret value.
- **Preview** (Ctrl+Space): separate window with text, image, or Quick Look for files; passwords are **masked** outside the Passwords tab.

### Paste and navigation

- Select an item and press **Return** to paste into the app that was active before the panel opened (⌘V simulation via Accessibility).
- **⌘0 … ⌘9** — quick paste by position in the current list.
- **Drag and drop** to reorder; moving to the top updates the system clipboard.
- Independent settings for **displaying** and **pasting** rich text (RTF/HTML).

### Panel layout

The app lives in the **menu bar** (no Dock icon). The history panel can be docked:

- left / right / top / bottom of the screen;
- centered (several sizes) or full screen.

The position is persisted in settings. Change it from the **Position** menu or with **Ctrl+Alt+⌘ + arrow keys** while the panel is open.

### Status item menu

- **Toggle Window** — show/hide the panel (default **⌘⇧V**, configurable in Preferences → Hot Key).
- **Launch at Login** — start at login.
- **Delete Selected** / **Clear history** — delete with a choice: history only, or everything including favorites and passwords.
- **Preferences**, **Help**, **About**.

### First launch

**Welcome** prompts for **Accessibility** access (required to simulate ⌘V in other apps). History still works without it; automatic paste does not.

---

## Security and privacy

VaultClip stores everything locally on your Mac. History and keys are never sent over the network.

### Encryption at rest

- History payloads are written with **AES-GCM** (CryptoKit, 256-bit key).
- On-disk format: `VC1` prefix + sealed box (nonce ‖ ciphertext ‖ tag).
- The symmetric key lives in the **macOS Keychain**:
  - service: `VaultClip`, account: `history-data-key`;
  - `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, no iCloud sync;
  - new keys request **user presence** (Touch ID / login password).
- **Metadata** (favorite flag, password flag, comment, copy time, source bundle id) uses the same encryption layer.
- Legacy **plaintext** files are read on open and re-encrypted on the next write. If decryption fails, raw bytes are returned so data is not lost after a key change.

### Filesystem hardening

- History directory: `~/Library/Application Support/VaultClip/history/` with mode **0700** (owner only).
- Before writing, paths are checked to reject **symlinks** outside the expected Application Support tree.
- Pasteboard type filenames are **sanitized** (encoding of `%`, `/`, `:`).

### Sensitive copy filtering

Copies from known **password managers** are not recorded (by source app bundle id), including:

1Password, LastPass, Bitwarden, Dashlane, Keeper, Elpass, Keychain Access, Apple Passwords, Proton Pass, NordPass, Enpass, and others.

Additional pasteboard types are dropped (transient, concealed, auto-generated, and vendor-specific password-manager UTIs).

### Passwords in the UI

- Items saved to **Passwords** show as `••••••••` in **History** and **Favorites** and are excluded from value-based search.
- The **Passwords** tab shows the real value and comment.
- **Preview** masks passwords outside the Passwords tab.
- Pasting a password shows a **warning**; `org.nspasteboard.ConcealedType` is added to the pasteboard where appropriate.

### Runtime and network

- **Hardened Runtime** is enabled for all build configurations.
- **App Transport Security** blocks arbitrary loads (`NSAllowsArbitraryLoads = false`). The app does not use network APIs for history.
- **App Sandbox** is **not** enabled in the current build (requires a separate entitlement plan for clipboard/accessibility with Developer ID signing).

### macOS permissions

| Permission | Why |
|------------|-----|
| **Accessibility** | One-shot ⌘V simulation into the previously focused app. No keystroke logging. |
| **Keychain** | Stores the encryption key; denial shows a dialog with a link to Keychain Access. |

System prompt strings are in `VaultClip/Supporting Files/Info.plist`.

### Data locations

```
~/Library/Application Support/VaultClip/
├── history/          # encrypted items (per UUID)
├── error.log
└── warning.log
```

Settings: `~/Library/Preferences/VaultClip.plist` (UserDefaults).

**Migration from Yippy:** on first launch after upgrading, data is moved from `~/Library/Application Support/MatthewDavidson.Yippy/`, and settings plus the Keychain key are copied automatically.

Deleting the `history-data-key` entry for VaultClip in Keychain Access **permanently breaks** decryption of existing history; the app will create a new key and start fresh.

---

## Keyboard shortcuts

Most shortcuts apply while the **history panel is open** (toggle is global):

| Shortcut | Action |
|----------|--------|
| **⌘⇧V** (default) | Open / close panel |
| **↑ / ↓** | Previous / next item |
| **Page Up / Page Down** | Scroll list |
| **Return** | Paste selection |
| **Esc** | Close panel |
| **⌘0 … ⌘9** | Paste item by index |
| **Ctrl+Delete** | Delete selection |
| **Ctrl+Space** | Toggle preview |
| **⌘\\** | Focus search |
| **Ctrl+[** / **Ctrl+]** | Previous / next tab |
| **Ctrl+Alt+⌘←→↑↓** | Move panel on screen |

Change the panel toggle in **Preferences → Hot Key**.

---

## Installation

1. Download `VaultClip.dmg` from [GitHub Releases](https://github.com/akarakuts/VaultClip/releases) **or** build from source (below).
2. Drag `VaultClip.app` into Applications.
3. On first launch, grant **Accessibility** (Welcome screen / System Settings → Privacy & Security → Accessibility).
4. When Keychain prompts appear, allow access to the encryption key.

### Build from source

Requirements: Xcode, macOS 10.15+, CocoaPods.

```bash
cd /path/to/VaultClip
pod install
open VaultClip.xcworkspace
```

Schemes:

- **VaultClip** — release (`VaultClip.app`);
- **VaultClip Beta** — beta (`VaultClip Beta.app`);
- **VaultClip XCTest** — unit and UI tests.

Release build:

```bash
xcodebuild -workspace VaultClip.xcworkspace -scheme VaultClip -configuration Release build
```

### Creating a DMG

Install [create-dmg](https://github.com/andreyvit/create-dmg), place `VaultClip.app` next to `create-installer.sh`:

```bash
./create-installer.sh VaultClip
```

`VaultClip.dmg` appears in the same folder.

---

## Development

Contributions welcome: [issues](https://github.com/akarakuts/VaultClip/issues) and [pull requests](https://github.com/akarakuts/VaultClip/pulls).

Project layout:

- `VaultClip/Sources/` — application code;
- `VaultClipTests/` — unit tests (58 tests);
- `VaultClipUITests/` — UI tests (require Accessibility in System Settings).

### Security-related modules

- `VaultClip/Sources/Models/Security/` — Keychain, AES-GCM, data migration;
- `SecureStorageHelper` — directory permissions and path validation;
- `DataFileManager` — `VC1` prefix and payload encryption;
- `History` — bundle id and pasteboard type denylists.

### Fork history (brief)

- `MACOSX_DEPLOYMENT_TARGET` raised to 10.15; ad-hoc signing for local builds.
- Removed `fatalError` in storyboard controllers; fixed `HistoryCache` races, subscription leaks, pasteboard and drag-and-drop edge cases.
- Renamed Yippy → VaultClip (code, bundle id, paths, Xcode schemes).
- Detailed technical changelog for earlier iterations lives in git history.

---

## License

VaultClip is licensed under the **GNU General Public License v3.0 or later** (GPL-3.0-or-later). See [LICENSE](LICENSE) for the full text.

This project is a fork of [Yippy](https://github.com/mattDavo/Yippy) by Matthew Davidson, originally released under the MIT License. GPLv3 applies to VaultClip as a whole, including modifications made in this fork.

Third-party libraries installed via CocoaPods remain under their respective licenses (see acknowledgements in the Pods build support files).

---

## Contact

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

Copyright (C) 2019 Matthew Davidson; Copyright (C) 2026 Aleksey Karakuts &lt;aleksey@karakuts.com&gt;. Licensed under GPLv3 or later.

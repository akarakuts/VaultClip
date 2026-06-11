# VaultClip

[![Release](https://img.shields.io/github/v/release/akarakuts/VaultClip)](https://github.com/akarakuts/VaultClip/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15%2B-000000?logo=apple)](https://github.com/akarakuts/VaultClip)

**Your clipboard, finally under control.** VaultClip is a macOS clipboard history manager: instant access to past copies, favorites at your fingertips, passwords kept apart from the main stream — all **encrypted on disk**, with no cloud and no subscriptions.

It lives in the menu bar, opens with **⌘⇧V**, and stays out of your way. Copy a snippet, link, screenshot, or PDF — a second later it is in history, with search and **⌘0…⌘9** quick-paste shortcuts.

Open-source fork of [Yippy](https://github.com/mattDavo/Yippy) by Matthew Davidson: the lean UX and “panel always nearby” idea are preserved; VaultClip adds **AES-GCM**, filtering of copies from password managers, **Favorites** and **Passwords** tabs, up-to-date toolchains, and an open roadmap.

**Repository:** [github.com/akarakuts/VaultClip](https://github.com/akarakuts/VaultClip) · **Русский:** [README.ru.md](README.ru.md)

<p align="center">
  <img src="images-en/screenshot-history.png" alt="VaultClip — History tab" width="78%">
</p>

<p align="center"><em>History, Favorites, and Passwords — one panel, three modes. UI in English and Russian.</em></p>

---

## Why VaultClip

| | |
|---|---|
| **Keep context** | Code, quotes, URLs, images — everything stays in local history until you decide otherwise. |
| **Keep secrets out of the noise** | Copies from 1Password, Bitwarden, and other managers **never enter** history; your own passwords go to the **Passwords** tab. |
| **Keep data off the cloud** | History stays on your Mac; the key lives in macOS Keychain. The app does not use the network for storage. |

VaultClip is not trying to replace a full password manager — it **tames clipboard chaos** and gives fast, predictable access to what you actually copy every day.

---

## See it in action

### History — the full timeline at hand

Text, code, links, colors, images, PDFs, and files in one list, with the source app icon and a timestamp. Re-copying the same content does not clutter the feed.

<p align="center">
  <img src="images-en/screenshot-history.png" alt="History tab — text, code, links, file previews" width="72%">
</p>

### Favorites — what you cannot afford to lose

Pin commands, SSH strings, documentation, and templates. Favorites survive ordinary history clears and are not pruned like one-off copies.

<p align="center">
  <img src="images-en/screenshot-favorites.png" alt="Favorites tab — pinned commands and links" width="72%">
</p>

### Passwords — separate and tidy

Saved entries show a comment, login, and masked secret. Search by comment and login; copy via the context menu. These rows **do not appear** in general history.

<p align="center">
  <img src="images-en/screenshot-passwords.png" alt="Passwords tab — login and masked password" width="72%">
</p>

---

## Features

### Clipboard history

- **Background monitoring** of the system pasteboard — every new copy (except filtered sources) is saved locally.
- **Up to 5000 items** in the model; settings can cap the displayed set (50–1500).
- **Content types:** text, RTF, HTML, URLs, colors, raster images, PDF, files with icon or preview.
- **Deduplication** within the last 20 items.
- **Source app icon** and **timestamp** on every row.

### Three tabs

| Tab | Purpose |
|-----|---------|
| **History** | Full timeline without favorites and saved passwords. |
| **Favorites** | Pinned items; protected from ordinary clears. |
| **Passwords** | Explicitly saved secrets: comment, login, `••••••••`. |

Favorites and saving to Passwords are available from the **context menu** (right-click): add/remove favorite, save to passwords, copy login/password, edit, delete.

### Search, preview, paste

- **Search** (⌘\\) — fuzzy text matching; for passwords, search runs on comment and login, not the secret.
- **Preview** (Ctrl+Space) — text, image, or Quick Look; passwords are masked outside the Passwords tab.
- **Return** — paste into the app that was active before the panel opened.
- **⌘0 … ⌘9** — quick paste by list position.
- **Drag and drop** to reorder; moving to the top updates the system clipboard.

### Panel and menu bar

**No Dock icon** — menu bar only. Dock the panel left, right, top, bottom, centered, or full screen; the position is remembered. Change it from the **Position** menu or with **Ctrl+Alt+⌘ + arrow keys**.

Menu items: **Toggle Window** (default **⌘⇧V**), launch at login, clear history, preferences, help.

### First launch and language

**Welcome** on first open requests **Accessibility** (needed for automatic ⌘V paste). Without it, history works; Return-to-paste does not.

UI in **English** and **Russian** (`Localizable.xcstrings`); the active language follows the system locale.

---

## Security and privacy

VaultClip is designed as **local storage**, not a sign-in service.

### Encryption at rest

- Item payloads use **AES-GCM** (CryptoKit, 256-bit key), `VC1` format + sealed box.
- Key in **macOS Keychain** (`com.karakuts.VaultClip` / `history-data-key`), `AfterFirstUnlockThisDeviceOnly`, no iCloud sync.
- Metadata (favorite flag, password flag, comment, login, time, bundle id) uses the same encryption layer.
- Legacy plaintext files are read and re-encrypted on write; migration from Yippy and early VaultClip is automatic.

### Leak prevention

- History directory: `~/Library/Application Support/com.karakuts.VaultClip/history/` with mode **0700**.
- Symlink checks on paths; sanitized pasteboard type filenames.
- **Denylist** of password-manager bundle ids (1Password, LastPass, Bitwarden, Dashlane, Keeper, Apple Passwords, Proton Pass, and others) and sensitive pasteboard types.
- **Hardened Runtime**; ATS blocks arbitrary HTTP loads. The app does not fetch history over the network.

### macOS permissions

| Permission | Why |
|--------------|-----|
| **Accessibility** | One-shot ⌘V simulation into the focused app. No keystroke logging. |
| **Keychain** | AES key with Developer ID signing. Ad-hoc builds fall back to `.history-encryption-key` (0600). |

Deleting the Keychain entry `history-data-key` **permanently breaks** decryption of existing history.

### Data locations

```
~/Library/Application Support/com.karakuts.VaultClip/
├── history/          # encrypted items (per UUID)
├── error.log
└── warning.log
```

Settings: `~/Library/Preferences/com.karakuts.VaultClip.plist` (UserDefaults).

**Migration from Yippy / VaultClip 1.1.2:** on first launch, data moves from `MatthewDavidson.Yippy` and `VaultClip` folders; settings and encryption keys are copied automatically.

---

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘⇧V** (default) | Open / close panel |
| **↑ / ↓**, **Page Up / Down** | Navigate the list |
| **Return** | Paste selection |
| **Esc** | Close panel |
| **⌘0 … ⌘9** | Paste by index |
| **Ctrl+Delete** | Delete selection |
| **Ctrl+Space** | Toggle preview |
| **⌘\\** | Focus search |
| **Ctrl+[** / **Ctrl+]** | Previous / next tab |
| **Ctrl+Alt+⌘←→↑↓** | Move panel on screen |

Change the panel toggle in **Preferences → Hot Key**.

---

## Installation

### Choose how to install

| Path | Cost | Best for |
|------|------|----------|
| **Build from source** (below) | Free | You, on your Mac — recommended without [Apple Developer Program](https://developer.apple.com/programs/) ($99/year) |
| **DMG from [GitHub Releases](https://github.com/akarakuts/VaultClip/releases)** | Free download | Quick try; may need Gatekeeper steps if the DMG is ad-hoc signed |
| **Signed + notarized DMG** | $99/year Apple program | Anyone can install without warnings — requires **Developer ID Application** |

Apple does **not** offer a free **Developer ID** certificate. Open source does not waive the fee. Without the paid program you can still use VaultClip by **building locally** or accepting macOS security prompts for an unsigned/ad-hoc DMG.

### Quick build (personal use, free)

Requirements: **Xcode**, **macOS 10.15+**, **CocoaPods** (`gem install cocoapods` or `brew install cocoapods`).

```bash
git clone https://github.com/akarakuts/VaultClip.git
cd VaultClip
pod install
VAULTCLIP_SIGN_RELEASE=1 ./build-dmg.sh
./install-app.sh VaultClip.app
open /Applications/VaultClip.app
```

`VAULTCLIP_SIGN_RELEASE=1` signs with **Developer ID Application** if present in Keychain; otherwise with **Apple Development** (created by Xcode on your Mac). Both work better than ad-hoc for **Accessibility** (paste into other apps).

To skip signing (fastest, least reliable for Accessibility):

```bash
./build-dmg.sh
./install-app.sh VaultClip.app
```

### Install to Applications

Always install under **`/Applications`** — not from the DMG volume and not by dragging from the repo folder (macOS resets Accessibility when the app path changes).

```bash
./install-app.sh VaultClip.app
# or, after build-dmg.sh:
./install-app.sh dmg-staging/VaultClip.app
```

The script uses `ditto --norsrc` and preserves an existing signature when possible.

### First launch

1. **Welcome** may ask for **Accessibility** — required for Return-to-paste (simulated ⌘V). History works without it; automatic paste does not.
2. **System Settings → Privacy & Security → Accessibility** — enable **VaultClip** once. Remove duplicate/stale entries if you reinstalled from another path.
3. Optional: menu bar **Launch at Login**.

### Code signing

| Mode | Command | Accessibility | Other Macs |
|------|---------|---------------|------------|
| **Ad-hoc** | `./build-dmg.sh` | Often broken | Gatekeeper blocks |
| **Apple Development** | `VAULTCLIP_SIGN_RELEASE=1 ./build-dmg.sh` | Usually OK on **your** Mac | Not for distribution |
| **Developer ID** | Same + cert in Keychain / CI secrets | OK | OK after notarization |

Signing logic: `codesign-app.sh` (Hardened Runtime; Keychain entitlements only with Developer ID).

### If macOS blocks the app (Gatekeeper)

Typical for ad-hoc or Apple Development DMGs on a Mac that did not build the app:

```bash
xattr -cr /Applications/VaultClip.app
```

Or right-click **VaultClip.app** → **Open** → confirm once. Prefer **build from source** on that Mac to avoid this.

### Build from source (step by step)

1. **Clone** the repo (see Quick build above).
2. **Dependencies:** `pod install` — opens `VaultClip.xcworkspace` (not `.xcodeproj`).
3. **Xcode schemes:**
   - **VaultClip** — release app;
   - **VaultClip Beta** — beta bundle;
   - **VaultClip XCTest** — unit and UI tests.
4. **DMG in one command:** `./build-dmg.sh` (see signing table above).
5. **Manual build** (without DMG script):

```bash
xcodebuild -workspace VaultClip.xcworkspace -scheme VaultClip -configuration Release \
  -destination 'platform=macOS' -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
COPYFILE_DISABLE=1 ditto --norsrc DerivedData/Build/Products/Release/VaultClip.app VaultClip.app
VAULTCLIP_SIGN_RELEASE=1 ./codesign-app.sh VaultClip.app
./install-app.sh VaultClip.app
```

6. **Run tests:**

```bash
xcodebuild -workspace VaultClip.xcworkspace -scheme VaultClip XCTest \
  -destination 'platform=macOS' -derivedDataPath DerivedData test
```

UI tests need Accessibility enabled for the test runner in System Settings.

### Public releases (Developer ID, optional)

For GitHub Release DMGs that install cleanly on **any** Mac, enroll in the [Apple Developer Program](https://developer.apple.com/programs/), create **Developer ID Application**, export `.p12`, and add repository secrets:

| Secret | Content |
|--------|---------|
| `MACOS_CERTIFICATE_P12` | Base64 of **Developer ID Application** `.p12` export |
| `MACOS_CERTIFICATE_PASSWORD` | Password for that `.p12` |
| `APPLE_ID` | Apple ID email (notarization, optional but recommended) |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) |
| `APPLE_TEAM_ID` | Team ID from the developer account |

```bash
# Keychain Access → My Certificates → Developer ID Application → Export → .p12
base64 -i DeveloperID.p12 | pbcopy   # paste into MACOS_CERTIFICATE_P12
```

The **Release** workflow (tag `v*`) imports the cert, signs with Hardened Runtime + Keychain entitlements, and notarizes when Apple ID secrets are set.

### After reinstall

Re-enable VaultClip in **System Settings → Privacy & Security → Accessibility**. Use `./install-app.sh` or `ditto --norsrc` — do not copy `.app` from the build tree with Finder drag-and-drop.

---

## Where the project is headed

VaultClip is an **active open-source fork** (GPLv3). Yippy provided a proven edge-of-screen UX; the next step is a **secure local layer** between macOS and your clipboard data.

**Already shipped:** AES-GCM encryption, Favorites and Passwords tabs, password-manager filtering, RU/EN localization, Yippy migration, Hardened Runtime, CI with Developer ID signing.

**On the horizon** (driven by community priorities and issues):

- sync **only when you choose** — local network or encrypted volume, no mandatory cloud;
- extensible filtering rules and tags for long history;
- accessibility improvements and **App Sandbox** while keeping paste via Accessibility;
- widgets and quick actions for common workflows (snippets, markdown, DevOps commands).

Ideas, bugs, and pull requests are welcome: [issues](https://github.com/akarakuts/VaultClip/issues) · [pull requests](https://github.com/akarakuts/VaultClip/pulls).

### For developers

- `VaultClip/Sources/` — application code;
- `VaultClip/Sources/Models/Security/` — Keychain, AES-GCM, migrations;
- `VaultClip/Resources/Localizable.xcstrings` — EN/RU UI strings;
- `VaultClipTests/` — unit tests; `VaultClipUITests/` — UI tests.

---

## License

**GNU General Public License v3.0 or later** (GPL-3.0-or-later). See [LICENSE](LICENSE).

Fork of [Yippy](https://github.com/mattDavo/Yippy) (Matthew Davidson), originally MIT. GPLv3 applies to VaultClip as a whole. CocoaPods dependencies remain under their own licenses.

---

## Contact

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

Copyright (C) 2019 Matthew Davidson; Copyright (C) 2026 Aleksey Karakuts &lt;aleksey@karakuts.com&gt;. Licensed under GPLv3 or later.

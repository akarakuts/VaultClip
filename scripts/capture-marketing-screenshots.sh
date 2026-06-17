#!/usr/bin/env bash
# Fills demo history, opens VaultClip on a clean desktop, captures three tab screenshots.
# Usage: capture-marketing-screenshots.sh [en]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCALE="${1:-}"
if [[ "$LOCALE" == "en" ]]; then
  IMAGES="$ROOT/images-en"
  MENU_TOGGLE="Toggle Window"
  TAB_HISTORY="History"
  TAB_FAVORITES="Favorites"
  TAB_PASSWORDS="Passwords"
else
  IMAGES="$ROOT/images"
  MENU_TOGGLE="Показать/скрыть окно"
  TAB_HISTORY="История"
  TAB_FAVORITES="Избранное"
  TAB_PASSWORDS="Пароли"
fi
ASSETS="$ROOT/scripts/demo-assets"
BACKUP=""
BUNDLE_ID="com.karakuts.VaultClip"
WALLPAPER=""
PANEL=""

cleanup() {
  rm -f "$PANEL" 2>/dev/null || true
  defaults write com.apple.finder CreateDesktop -bool true 2>/dev/null || true
  killall Finder 2>/dev/null || true
  if [[ -n "$BACKUP" && -d "$BACKUP/history" ]]; then
    rm -rf "$HOME/Library/Application Support/$BUNDLE_ID/history"
    cp -R "$BACKUP/history" "$HOME/Library/Application Support/$BUNDLE_ID/"
  fi
  if [[ "$LOCALE" == "en" ]]; then
    defaults delete "$BUNDLE_ID" AppleLanguages 2>/dev/null || true
    defaults delete "$BUNDLE_ID" AppleLocale 2>/dev/null || true
  fi
  killall VaultClip 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$IMAGES" "$ASSETS"

APP="/Applications/VaultClip.app"
[[ -d "$APP" ]] || APP="$ROOT/DerivedData/Build/Products/Release/VaultClip.app"
[[ -d "$APP" ]] || { echo "VaultClip.app not found." >&2; exit 1; }

BACKUP="$(mktemp -d)"
[[ -d "$HOME/Library/Application Support/com.karakuts.VaultClip/history" ]] && \
  cp -R "$HOME/Library/Application Support/com.karakuts.VaultClip/history" "$BACKUP/"

killall VaultClip 2>/dev/null || true
chmod +x "$ROOT/scripts/seed-demo-history.swift"
swift "$ROOT/scripts/seed-demo-history.swift"

defaults write com.apple.finder CreateDesktop -bool false
killall Finder 2>/dev/null || true
sleep 1

PANEL="$(mktemp /tmp/vaultclip-panel.XXXXXX.png)"
WALLPAPER="$ASSETS/desktop-wallpaper.png"
chmod +x "$ROOT/scripts/extract-wallpaper-plate.swift"
swift "$ROOT/scripts/extract-wallpaper-plate.swift" "$ROOT"

# Hide visible apps (keep Finder for clean desktop).
osascript <<'APPLESCRIPT' || true
tell application "System Events"
  repeat with p in (every application process whose visible is true)
    try
      set n to name of p
      if n is not "Finder" and n is not "Dock" and n is not "Wallpaper" then
        set visible of p to false
      end if
    end try
  end repeat
end tell
tell application "Finder" to activate
delay 0.4
tell application "System Events" to keystroke "h" using {command down, option down}
APPLESCRIPT
sleep 0.5

# Pasteboard on launch is synced into history — use content already in the seeded set (dedup skips it).
printf 'https://github.com/akarakuts/VaultClip' | pbcopy

if [[ "$LOCALE" == "en" ]]; then
  defaults write "$BUNDLE_ID" AppleLanguages -array "en"
  defaults write "$BUNDLE_ID" AppleLocale -string "en_US"
fi

printf 'https://github.com/akarakuts/VaultClip' | pbcopy
open -gn "$APP"
sleep 4

open_history_panel() {
  osascript - "$MENU_TOGGLE" <<'APPLESCRIPT' || return 1
on run argv
  set menuTitle to item 1 of argv
  tell application "VaultClip" to activate
  delay 0.5
  tell application "System Events"
    tell process "VaultClip"
      set frontmost to true
      try
        click menu bar item 1 of menu bar 2
        delay 0.2
        click menu item menuTitle of menu 1 of menu bar item 1 of menu bar 2
      on error
        keystroke "v" using {command down, shift down}
      end try
    end tell
  end tell
end run
APPLESCRIPT
}

if ! open_history_panel; then
  echo "Failed to open history panel (grant Accessibility to Terminal/Cursor)." >&2
  exit 1
fi

WINDOW_ID=""
wait_window() {
  local i wid
  for i in $(seq 1 40); do
    if wid=$(swift "$ROOT/scripts/wait-history-window.swift" 2>/dev/null); then
      WINDOW_ID="$wid"
      return 0
    fi
    sleep 0.15
  done
  return 1
}

if ! wait_window; then
  echo "History window did not appear." >&2
  exit 1
fi

# Hide Finder so only wallpaper + VaultClip panel remain.
osascript -e 'tell application "System Events" to set visible of process "Finder" to false' || true
sleep 0.4

hide_other_apps() {
  osascript <<'APPLESCRIPT' || true
tell application "VaultClip" to activate
tell application "System Events"
  tell process "VaultClip" to set frontmost to true
  repeat with proc in (every application process whose visible is true)
    set n to name of proc
    if n is not "VaultClip" then
      try
        set visible of proc to false
      end try
    end if
  end repeat
  tell process "VaultClip" to set frontmost to true
end tell
APPLESCRIPT
  sleep 0.35
}

select_tab() {
  chmod +x "$ROOT/scripts/click-history-tab.swift"
  swift "$ROOT/scripts/click-history-tab.swift" "$1"
  sleep 0.7
}

focus_vaultclip() {
  osascript <<'APPLESCRIPT' || true
tell application "VaultClip" to activate
delay 0.2
tell application "System Events" to tell process "VaultClip" to set frontmost to true
APPLESCRIPT
}

clear_search_and_focus_list() {
  focus_vaultclip
  osascript <<'APPLESCRIPT' || true
tell application "System Events"
  tell process "VaultClip"
    set frontmost to true
    try
      set searchField to text field 1 of window 1
      click searchField
      keystroke "a" using command down
      key code 51
    end try
    try
      click table 1 of scroll area 1 of window 1
    end try
  end tell
end tell
APPLESCRIPT
  sleep 0.35
}

capture() {
  hide_other_apps
  focus_vaultclip
  local bounds wid winX winY winW winH
  bounds=$(swift "$ROOT/scripts/get-history-window-bounds.swift") || return 1
  read -r wid winX winY winW winH <<<"$bounds"
  screencapture -l "$wid" -o -x "$PANEL"
  swift "$ROOT/scripts/composite-wallpaper-shot.swift" \
    "$WALLPAPER" "$PANEL" "$IMAGES/$1" "$winX" "$winY" "$winW" "$winH"
  echo "Saved $IMAGES/$1"
}

hide_other_apps
select_tab 0
capture "screenshot-history.png"

select_tab 1
capture "screenshot-favorites.png"

select_tab 2
capture "screenshot-passwords.png"

cp -f "$IMAGES/screenshot-history.png" "$IMAGES/screenshot.jpg"
ls -lh "$IMAGES"/screenshot-*.png "$IMAGES/screenshot.jpg"
echo "Done: $IMAGES"

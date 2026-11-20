#!/usr/bin/env bash
# ui-preview.sh — build the XCTest-config app, seed demo history in /tmp and open the panel (U36).
# Uses bundle id com.karakuts.VaultClipXCTest + --storage-root; never touches production Application Support.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="/tmp/vc-ui"
STORE="/tmp/vc-ui-root"
SHOTS="/tmp/vc-ui-shots"
BID="com.karakuts.VaultClipXCTest"
mkdir -p "$OUT" "$SHOTS"
cd "$ROOT"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  xcodebuild \
    -project VaultClip.xcodeproj \
    -scheme VaultClip \
    -configuration XCTest \
    -derivedDataPath "$OUT" \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
    build >/tmp/vc-ui-build.log 2>&1 || { tail -30 /tmp/vc-ui-build.log; exit 1; }
fi

APP="$(find "$OUT/Build/Products" -maxdepth 2 -name 'VaultClip.app' -type d | head -1)"
if [ -z "$APP" ]; then
  echo "error: VaultClip.app not found under $OUT" >&2
  exit 1
fi
ACTUAL="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
if [ "$ACTUAL" != "$BID" ]; then
  echo "error: refusing non-XCTest bundle id: $ACTUAL" >&2
  exit 1
fi

pkill -f "$APP/Contents/MacOS/" >/dev/null 2>&1 || true
rm -rf "$STORE"
# EMPTY=1 checks the empty-history state.
if [ "${EMPTY:-0}" != "1" ]; then
  VAULTCLIP_SEED_APP_SUPPORT="$STORE/$BID" swift "$ROOT/scripts/seed-demo-history.swift"
fi

open -n "$APP" --args --storage-root="$STORE" --open-panel "$@"
echo "ui-preview running: $APP (storage $STORE)"
echo "stop: pkill -f '$APP/Contents/MacOS/'"

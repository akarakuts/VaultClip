#!/usr/bin/env bash
# ui-preview.sh — build XCTest host and optionally capture panel screenshots (U36).
# Only uses the XCTest bundle id; never touches production Application Support.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="/tmp/vc-ui"
SHOTS="/tmp/vc-ui-shots"
mkdir -p "$OUT" "$SHOTS"
cd "$ROOT"

xcodebuild \
  -scheme "VaultClip XCTest" \
  -configuration Debug \
  -derivedDataPath "$OUT" \
  -destination 'platform=macOS' \
  build-for-testing

APP="$(find "$OUT" -path '*/VaultClip.app' -type d | head -1)"
if [ -z "$APP" ]; then
  echo "error: VaultClip.app not found under $OUT" >&2
  exit 1
fi
BID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
if [ "$BID" != "com.karakuts.VaultClipXCTest" ]; then
  echo "error: refusing non-XCTest bundle id: $BID" >&2
  exit 1
fi

ARGS=(--uitesting --demo-items=40 --open-panel --panel-position=right --appearance=light --text-size=m)
open -n "$APP" --args "${ARGS[@]}"
sleep 3
# Screen Recording entitlement may be missing — mark manual if capture fails.
if ! screencapture -x "$SHOTS/panel-right-light-m.png" 2>/dev/null; then
  echo "requires manual check: Screen Recording not available for screencapture"
fi
pkill -f "$APP" >/dev/null 2>&1 || true
echo "ui-preview done; shots in $SHOTS"

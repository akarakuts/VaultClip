#!/usr/bin/env bash
# verify-panel-themes-visual.sh — ui-preview themes: relaunch per theme + live apply (preview arg).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="/tmp/vc-ui"
STORE="/tmp/vc-ui-root"
SHOTS="/tmp/vc-ui-shots"
BID="com.karakuts.VaultClipXCTest"
PLIST="$HOME/Library/Preferences/${BID}.plist"
APP="$OUT/Build/Products/XCTest/VaultClip.app"

mkdir -p "$SHOTS"
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

if [ ! -d "$APP" ]; then
  echo "error: missing $APP" >&2
  exit 1
fi

python3 - "$BID" "$PLIST" "$APP" "$STORE" "$SHOTS" <<'PY'
import json, plistlib, subprocess, sys, time
from pathlib import Path

bundle, plist_path, app, store, shots = sys.argv[1:6]
plist_path = Path(plist_path)
app = Path(app)
shots = Path(shots)
themes = ["system", "light", "dark", "liquidGlass"]

def load_settings():
    with open(plist_path, "rb") as f:
        pl = plistlib.load(f)
    raw = pl.get("settings")
    if not raw:
        return {}, pl
    if isinstance(raw, bytes):
        return json.loads(raw.decode("utf-8")), pl
    if isinstance(raw, str):
        return json.loads(raw), pl
    raise SystemExit("unexpected settings type in plist")

def save_settings(settings, pl):
    pl["settings"] = json.dumps(settings, separators=(",", ":")).encode("utf-8")
    with open(plist_path, "wb") as f:
        plistlib.dump(pl, f)

def stop_app():
    subprocess.run(["pkill", "-f", f"{app}/Contents/MacOS/"], check=False)

def launch(*extra_args: str):
    stop_app()
    time.sleep(0.5)
    args = [str(app), "--args", f"--storage-root={store}", "--open-panel", *extra_args]
    subprocess.run(["open", "-n", *args], check=True)
    time.sleep(2.8)

def capture(label: str) -> Path:
    subprocess.run(["osascript", "-e", 'tell application "VaultClip" to activate'], check=False)
    time.sleep(0.7)
    out = shots / f"panel-theme-{label}.png"
    subprocess.run(["screencapture", "-x", str(out)], check=True)
    return out

def open_panel_settings_tab():
  subprocess.run(["defaults", "write", bundle, "settings.lastTabIndex", "-int", "1"], check=True)

settings, pl = load_settings()
for theme in themes:
    settings = json.loads(json.dumps(settings))
    settings["panelAppearance"] = theme
    save_settings(settings, pl)
    launch()
    shot = capture(theme)
    print(f"  {theme}: screenshot_bytes={shot.stat().st_size}")

# Live apply: panel stays open; preview hook sets dark at t=3.5s.
settings["panelAppearance"] = "system"
save_settings(settings, pl)
launch("--preview-set-appearance=dark")
time.sleep(2.0)
capture("live-before-dark")
time.sleep(2.5)
shot_after = capture("live-after-dark")
print(f"  live-apply: before+after bytes; after={shot_after.stat().st_size}")

open_panel_settings_tab()
stop_app()
time.sleep(0.4)
subprocess.run(
    ["open", "-n", str(app), "--args", f"--storage-root={store}", "--open-panel", "--panel-command=openSettings"],
    check=True,
)
time.sleep(3)
subprocess.run(["osascript", "-e", 'tell application "VaultClip" to activate'], check=False)
time.sleep(0.5)
settings_win = shots / "settings-panel-appearance.png"
subprocess.run(["screencapture", "-x", str(settings_win)], check=True)
print(f"  settings-picker: screenshot_bytes={settings_win.stat().st_size}")
print("VERIFY_PANEL_THEMES OK")
PY

echo "Screenshots in $SHOTS"
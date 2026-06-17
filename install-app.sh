#!/bin/sh
# Install VaultClip.app to /Applications. Preserves Developer ID signature; ad-hoc only when needed.
set -eu
cd "$(dirname "$0")"

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
    NEWEST=""
    NEWEST_MTIME=0
    for candidate in \
        DerivedData/Build/Products/Release/VaultClip.app \
        dmg-staging/VaultClip.app \
        VaultClip.app; do
        binary="$candidate/Contents/MacOS/VaultClip"
        if [ -f "$binary" ]; then
            mtime=$(stat -f %m "$binary" 2>/dev/null || stat -c %Y "$binary" 2>/dev/null || echo 0)
            if [ "$mtime" -gt "$NEWEST_MTIME" ]; then
                NEWEST_MTIME=$mtime
                NEWEST=$candidate
            fi
        fi
    done
    if [ -z "$NEWEST" ]; then
        echo "Usage: ./install-app.sh [path/to/VaultClip.app]" >&2
        echo "Run xcodebuild or ./build-dmg.sh first, or pass a signed .app bundle." >&2
        exit 1
    fi
    SOURCE=$NEWEST
    echo "Using newest build: $SOURCE"
fi

if [ ! -d "$SOURCE" ]; then
    echo "install-app.sh: not found: $SOURCE" >&2
    exit 1
fi

SIGNED=$(mktemp -d)
trap 'rm -rf "$SIGNED"' EXIT
COPYFILE_DISABLE=1 ditto --norsrc "$SOURCE" "$SIGNED/VaultClip.app"

needs_resign() {
    if ! codesign --verify --deep --strict "$SIGNED/VaultClip.app" 2>/dev/null; then
        return 0
    fi
    if codesign -dv "$SIGNED/VaultClip.app" 2>&1 | grep -q 'Signature=adhoc'; then
        return 0
    fi
    if codesign -dv "$SIGNED/VaultClip.app" 2>&1 | grep -q 'TeamIdentifier=not set'; then
        return 0
    fi
    return 1
}

chmod +x ./codesign-app.sh
if needs_resign; then
    echo "Re-signing (unsigned or ad-hoc)…"
    ./codesign-app.sh "$SIGNED/VaultClip.app"
else
    echo "Keeping existing Developer ID / Apple Development signature."
fi

killall VaultClip 2>/dev/null || true
rm -rf /Applications/VaultClip.app
COPYFILE_DISABLE=1 ditto --norsrc "$SIGNED/VaultClip.app" /Applications/VaultClip.app

codesign --verify --deep --strict /Applications/VaultClip.app
echo "Installed: /Applications/VaultClip.app"
codesign -dv --verbose=2 /Applications/VaultClip.app 2>&1 | awk -F= '/Authority|Identifier|TeamIdentifier/ {print}'
echo ""
echo "1. Open System Settings → Privacy & Security → Accessibility."
echo "2. Remove old VaultClip entries, enable the one from /Applications."
echo "3. Quit and reopen VaultClip (or run: open /Applications/VaultClip.app)."

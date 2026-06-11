#!/bin/sh
# Notarize VaultClip.dmg (requires APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID).
set -eu
cd "$(dirname "$0")"

DMG="${1:-VaultClip.dmg}"

for var in APPLE_ID APPLE_APP_SPECIFIC_PASSWORD APPLE_TEAM_ID; do
    eval "val=\${$var:-}"
    if [ -z "$val" ]; then
        echo "notarize-dmg.sh: set $var" >&2
        exit 1
    fi
done

if [ ! -f "$DMG" ]; then
    echo "notarize-dmg.sh: not found: $DMG" >&2
    exit 1
fi

echo "Submitting $DMG for notarization…"
xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

echo "Stapling ticket to $DMG…"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
echo "Notarized and stapled: $DMG"

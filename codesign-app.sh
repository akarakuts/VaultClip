#!/bin/sh
# Sign VaultClip.app for local DMG / install.
#
# Ad-hoc (default): no Apple cert — Accessibility / Keychain are unreliable.
# Release: set VAULTCLIP_SIGN_IDENTITY to a Developer ID Application identity, e.g. from CI:
#   VAULTCLIP_SIGN_IDENTITY="Developer ID Application: Aleksey Karakuts (PDQFD8QZA3)"
set -eu
cd "$(dirname "$0")"

APP="${1:-VaultClip.app}"
ENTITLEMENTS_RELEASE="VaultClip/Supporting Files/VaultClip.entitlements"
ENTITLEMENTS_ADHOC="VaultClip/Supporting Files/VaultClip.adhoc.entitlements"

if [ ! -d "$APP" ]; then
    echo "codesign-app.sh: not found: $APP" >&2
    exit 1
fi

resolve_sign_identity() {
    if [ -n "${VAULTCLIP_SIGN_IDENTITY:-}" ]; then
        ident="$VAULTCLIP_SIGN_IDENTITY"
        # Duplicate cert names in Keychain → codesign fails; use SHA-1 of first match.
        if ! printf '%s' "$ident" | grep -qE '^[A-F0-9a-f]{40}$'; then
            hash=$(security find-identity -v -p codesigning 2>/dev/null \
                | grep -F "\"$ident\"" | head -1 \
                | sed -E 's/^[[:space:]]+[0-9]+\) ([A-F0-9]{40}) .*/\1/')
            if [ -n "$hash" ]; then
                ident="$hash"
            fi
        fi
        echo "$ident"
        return 0
    fi
    if [ "${VAULTCLIP_SIGN_RELEASE:-}" = "1" ]; then
        ident=$(security find-identity -v -p codesigning 2>/dev/null \
            | awk -F'"' '/Developer ID Application/ { print $2; exit }')
        if [ -z "$ident" ]; then
            ident=$(security find-identity -v -p codesigning 2>/dev/null \
                | awk -F'"' '/Apple Development/ { print $2; exit }')
        fi
        if [ -n "$ident" ]; then
            hash=$(security find-identity -v -p codesigning 2>/dev/null \
                | grep -F "\"$ident\"" | head -1 \
                | sed -E 's/^[[:space:]]+[0-9]+\) ([A-F0-9]{40}) .*/\1/')
            if [ -n "$hash" ]; then
                echo "$hash"
            else
                echo "$ident"
            fi
        fi
        return 0
    fi
    echo "-"
}

SIGN_IDENTITY=$(resolve_sign_identity)
if [ -z "$SIGN_IDENTITY" ]; then
    echo "codesign-app.sh: VAULTCLIP_SIGN_RELEASE=1 but no signing identity in keychain" >&2
    exit 1
fi

is_developer_id_identity() {
    [ "$SIGN_IDENTITY" = "-" ] && return 1
    security find-identity -v -p codesigning 2>/dev/null \
        | grep -F "$SIGN_IDENTITY" | grep -q "Developer ID Application"
}

if [ "$SIGN_IDENTITY" = "-" ]; then
    ENTITLEMENTS="$ENTITLEMENTS_ADHOC"
    SIGN_FLAGS="--timestamp=none"
    SIGN_LABEL="Ad-hoc"
elif is_developer_id_identity; then
    ENTITLEMENTS="$ENTITLEMENTS_RELEASE"
    SIGN_FLAGS="--timestamp --options runtime"
    SIGN_LABEL="Developer ID"
else
    # Apple Development without embedded profile: keychain-access-groups → AMFI error 163 at launch.
    ENTITLEMENTS="$ENTITLEMENTS_ADHOC"
    SIGN_FLAGS="--timestamp --options runtime"
    SIGN_LABEL="Apple Development"
fi

if [ ! -f "$ENTITLEMENTS" ]; then
    echo "codesign-app.sh: missing $ENTITLEMENTS" >&2
    exit 1
fi

# Strip resource forks / provenance that break codesign (common after cp or Finder copy).
TMP=$(mktemp -d)
COPYFILE_DISABLE=1 ditto --norsrc "$APP" "$TMP/$(basename "$APP")"
rm -rf "$APP"
COPYFILE_DISABLE=1 ditto --norsrc "$TMP/$(basename "$APP")" "$APP"
rm -rf "$TMP"
xattr -cr "$APP" 2>/dev/null || true

sign_binary() {
    # shellcheck disable=SC2086
    codesign --force --sign "$SIGN_IDENTITY" $SIGN_FLAGS "$1"
}

if [ -d "$APP/Contents/Frameworks" ]; then
    find "$APP/Contents/Frameworks" -type f -name '*.dylib' -print0 | while IFS= read -r -d '' lib; do
        sign_binary "$lib"
    done
    find "$APP/Contents/Frameworks" -type d -name '*.framework' -print0 | while IFS= read -r -d '' fw; do
        sign_binary "$fw"
    done
fi

# shellcheck disable=SC2086
codesign --force --sign "$SIGN_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    $SIGN_FLAGS \
    "$APP"

codesign --verify --deep --strict "$APP"
echo "$SIGN_LABEL signed: $APP"
codesign -dv --verbose=2 "$APP" 2>&1 | awk -F= '/Authority|Identifier|TeamIdentifier/ {print}'

if [ "$SIGN_IDENTITY" = "-" ]; then
    echo "Note: ad-hoc builds often fail Accessibility. Use Developer ID or Apple Development for local testing."
fi

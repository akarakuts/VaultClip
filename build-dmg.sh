#!/bin/sh
# Build VaultClip.app and VaultClip.dmg from the command line (same flags as CI).
set -eu
cd "$(dirname "$0")"

echo "Building Release…"
xcodebuild \
  -workspace VaultClip.xcworkspace \
  -scheme VaultClip \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

SIGNED=$(mktemp -d)
trap 'rm -rf "$SIGNED"' EXIT
COPYFILE_DISABLE=1 ditto --norsrc DerivedData/Build/Products/Release/VaultClip.app "$SIGNED/VaultClip.app"

chmod +x ./codesign-app.sh
if [ -n "${VAULTCLIP_SIGN_IDENTITY:-}" ] || [ "${VAULTCLIP_SIGN_RELEASE:-}" = "1" ]; then
    echo "Signing with Apple certificate…"
    if [ -z "${VAULTCLIP_SIGN_IDENTITY:-}" ]; then
        export VAULTCLIP_SIGN_RELEASE=1
    fi
else
    echo "Ad-hoc signing (local only — Accessibility may not work; set VAULTCLIP_SIGN_RELEASE=1 with a cert for release)…"
fi
./codesign-app.sh "$SIGNED/VaultClip.app"

echo "Creating DMG…"
rm -rf dmg-staging VaultClip.dmg
mkdir dmg-staging
COPYFILE_DISABLE=1 ditto --norsrc "$SIGNED/VaultClip.app" dmg-staging/VaultClip.app
( cd dmg-staging && ../create-installer.sh VaultClip && mv VaultClip.dmg .. )

rm -rf VaultClip.app
COPYFILE_DISABLE=1 ditto --norsrc "$SIGNED/VaultClip.app" VaultClip.app

ls -lh VaultClip.dmg
echo "Done: $(pwd)/VaultClip.dmg"
echo ""
echo "Install to /Applications (replace existing copy):"
echo "  killall VaultClip 2>/dev/null; rm -rf /Applications/VaultClip.app"
echo "  COPYFILE_DISABLE=1 ditto --norsrc \"$SIGNED/VaultClip.app\" /Applications/VaultClip.app"
echo "  open /Applications/VaultClip.app"
echo ""
echo "Then enable VaultClip in System Settings → Privacy & Security → Accessibility."

#!/bin/sh
# Import a .p12 signing certificate into an ephemeral keychain (CI or local).
# Requires: MACOS_CERTIFICATE_P12 (base64) and MACOS_CERTIFICATE_PASSWORD.
set -eu

if [ -z "${MACOS_CERTIFICATE_P12:-}" ] || [ -z "${MACOS_CERTIFICATE_PASSWORD:-}" ]; then
    echo "import-macos-certificate.sh: set MACOS_CERTIFICATE_P12 and MACOS_CERTIFICATE_PASSWORD" >&2
    exit 1
fi

KEYCHAIN="${MACOS_KEYCHAIN_PATH:-$RUNNER_TEMP/build.keychain}"
KEYCHAIN_PASSWORD="${MACOS_KEYCHAIN_PASSWORD:-}"

if [ -z "$KEYCHAIN_PASSWORD" ]; then
    KEYCHAIN_PASSWORD=$(openssl rand -hex 16)
fi

CERT_PATH="${RUNNER_TEMP:-/tmp}/vaultclip-signing.p12"
echo "$MACOS_CERTIFICATE_P12" | base64 --decode > "$CERT_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security default-keychain -s "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security import "$CERT_PATH" -k "$KEYCHAIN" -P "$MACOS_CERTIFICATE_PASSWORD" \
    -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productsign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')

rm -f "$CERT_PATH"
echo "Certificate imported into: $KEYCHAIN"

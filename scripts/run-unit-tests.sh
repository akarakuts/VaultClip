#!/bin/sh
# Run VaultClip unit tests (same flags as CI).
set -eu
cd "$(dirname "$0")/.."

xcodebuild test \
  -project VaultClip.xcodeproj \
  -scheme "VaultClip XCTest" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData \
  -only-testing:VaultClipTests \
  -enableCodeCoverage YES \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

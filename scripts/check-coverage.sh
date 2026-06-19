#!/bin/sh
# Fail CI when line coverage for Security + History modules drops below threshold.
set -eu
cd "$(dirname "$0")/.."

THRESHOLD="${VAULTCLIP_COVERAGE_THRESHOLD:-55}"
RESULT="${1:-DerivedData/Logs/Test}"

XCRESULT="$(find "$RESULT" -name '*.xcresult' -type d 2>/dev/null | sort -r | head -1)"
if [ -z "$XCRESULT" ]; then
  echo "error: no .xcresult under $RESULT — run unit tests first" >&2
  exit 1
fi

REPORT="$(mktemp)"
xcrun xccov view --report "$XCRESULT" > "$REPORT"

pct_from_line() {
  sed -n 's/.* \([0-9][0-9.]*\)% .*/\1/p'
}

overall="$(grep 'VaultClip.app' "$REPORT" | head -1 | pct_from_line)"
security="$(grep '/Sources/Models/Security/' "$REPORT" | pct_from_line | sort -n | tail -1)"
history="$(grep '/Sources/Models/History/' "$REPORT" | pct_from_line | sort -n | tail -1)"

echo "Coverage — app: ${overall:-?}%  security peak: ${security:-0}%  history peak: ${history:-0}%  (threshold ${THRESHOLD}%)"

peak="$(printf '%s\n%s\n' "${security:-0}" "${history:-0}" | sort -n | tail -1)"
if ! awk -v p="$peak" -v t="$THRESHOLD" 'BEGIN { exit (p+0 >= t+0) ? 0 : 1 }'; then
  echo "error: module coverage below ${THRESHOLD}%" >&2
  exit 1
fi

rm -f "$REPORT"

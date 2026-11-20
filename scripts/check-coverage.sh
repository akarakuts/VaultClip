#!/bin/sh
# Fail CI when line coverage of the core Security + History files drops below threshold.
#
# The gate is the MINIMUM per-file line coverage across the GATED list — not the
# module peak — so one regressed file cannot hide behind a 100% sibling.
#
# Excluded from the gate (structurally low unit-testability, listed with reason):
#   AppDataMigrator.swift      - one-shot Yippy migration, needs a legacy on-disk
#                                layout the tests do not control
#   SymmetricKeyStore.swift    - Keychain/file I/O wiring; selection logic lives in KeyResolver
#   EncryptionKeyBootstrap.swift - launch NSAlert recovery UI
#   HistoryFileManaging.swift  - protocol + default-forwarding shims exercised via mocks
#   ArrayFileManager.swift     - 19 lines, remainder is FileManager error branches
#   HistoryItem+Password.swift - 11 lines, keychain-backed favorite/password toggles
set -eu
cd "$(dirname "$0")/.."

THRESHOLD="${VAULTCLIP_COVERAGE_THRESHOLD:-55}"
RESULT="${1:-DerivedData/Logs/Test}"

GATED="
AESGCMDataEncryptor.swift
SecureStorageHelper.swift
KeychainSymmetricKeyStore.swift
KeyResolver.swift
History.swift
HistoryCache.swift
HistoryFileManager.swift
HistoryItem.swift
HistoryItem+CopiedAt.swift
HistoryItem+HistoryListItem.swift
HistoryItem+Image.swift
HistoryListMode.swift
HistoryPasteboardPolicy.swift
DataFileManager.swift
"

XCRESULT="$(find "$RESULT" -name '*.xcresult' -type d 2>/dev/null | sort -r | head -1)"
if [ -z "$XCRESULT" ]; then
  echo "error: no .xcresult under $RESULT — run unit tests first" >&2
  exit 1
fi

REPORT="$(mktemp)"
trap 'rm -f "$REPORT"' EXIT
xcrun xccov view --report "$XCRESULT" > "$REPORT"

overall="$(awk '$1 ~ /VaultClip\.app\/?$/ { gsub(/%/, "", $2); print $2; exit }' "$REPORT")"
echo "Coverage gate — app overall: ${overall:-?}%  (threshold ${THRESHOLD}%)"

min=""
min_file=""
for name in $GATED; do
  pct="$(awk -v f="$name" '{ n = split($1, p, "/"); if (p[n] == f) { gsub(/%/, "", $2); print $2; exit } }' "$REPORT")"
  if [ -z "$pct" ]; then
    echo "error: $name missing from coverage report (renamed? tests not run?)" >&2
    exit 1
  fi
  echo "  ${pct}%  $name"
  if [ -z "$min" ] || awk -v a="$pct" -v b="$min" 'BEGIN { exit (a+0 < b+0) ? 0 : 1 }'; then
    min="$pct"
    min_file="$name"
  fi
done

if [ -z "$min" ]; then
  echo "error: no gated files found in coverage report" >&2
  exit 1
fi

if ! awk -v p="$min" -v t="$THRESHOLD" 'BEGIN { exit (p+0 >= t+0) ? 0 : 1 }'; then
  echo "error: lowest gated file coverage ${min}% ($min_file) is below ${THRESHOLD}%" >&2
  exit 1
fi

echo "OK — minimum gated coverage ${min}% ($min_file) >= ${THRESHOLD}%"

STRICT_THRESHOLD="${VAULTCLIP_STRICT_COVERAGE_THRESHOLD:-80}"
GATED_STRICT="
PanelCommand.swift
KeyChordMatcher.swift
PanelKeyRouter.swift
EscapeResolver.swift
ItemKind.swift
RowPresentation.swift
PanelPresenter.swift
DateGrouping.swift
FilterState.swift
MultiPasteComposer.swift
PendingDeletionQueue.swift
PreviewLayout.swift
MenuBarModel.swift
CommandPaletteModel.swift
"

strict_min=""
strict_file=""
for name in $GATED_STRICT; do
  pct="$(awk -v f="$name" '{ n = split($1, p, "/"); if (p[n] == f) { gsub(/%/, "", $2); print $2; exit } }' "$REPORT")"
  if [ -z "$pct" ]; then
    echo "warn: strict file $name missing from coverage report — skip"
    continue
  fi
  echo "  strict ${pct}%  $name"
  if [ -z "$strict_min" ] || awk -v a="$pct" -v b="$strict_min" 'BEGIN { exit (a+0 < b+0) ? 0 : 1 }'; then
    strict_min="$pct"
    strict_file="$name"
  fi
done

if [ -n "$strict_min" ]; then
  if ! awk -v p="$strict_min" -v t="$STRICT_THRESHOLD" 'BEGIN { exit (p+0 >= t+0) ? 0 : 1 }'; then
    echo "error: lowest strict gated coverage ${strict_min}% ($strict_file) is below ${STRICT_THRESHOLD}%" >&2
    exit 1
  fi
  echo "OK — minimum strict coverage ${strict_min}% ($strict_file) >= ${STRICT_THRESHOLD}%"
fi

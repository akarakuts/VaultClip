#!/usr/bin/env bash
# Запускает sidecar Computer Use и открывает TCC «Запись экрана».
# В списке должен быть пункт «Cursor Computer Use» (не только «Cursor»).
set -eu
CUAPP="${HOME}/.cursor/computer-use-sidecar/Cursor Computer Use.app"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" 2>/dev/null \
  || open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
if [ -d "$CUAPP" ]; then
  open -a "$CUAPP"
  echo "Запущен: Cursor Computer Use (${CUAPP})"
else
  echo "warning: sidecar не найден; перезапустите Cursor" >&2
fi
echo "Включите «Cursor Computer Use» и «Cursor» → Запись экрана, затем ⌘Q Cursor и откройте снова."
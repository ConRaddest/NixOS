#!/usr/bin/env bash
set -euo pipefail

# Never start a second hyprlock. Multiple lockers competing for the
# session-lock protocol are a common cause of broken/black unlocks.
if pgrep -u "$UID" -x hyprlock >/dev/null; then
  nos-lock-idle >/dev/null 2>&1 &
  exit 0
fi

hyprctl dispatch dpms on >/dev/null 2>&1 || true
hyprlock --immediate-render --no-fade-in >"${XDG_RUNTIME_DIR:-/tmp}/hyprlock-$UID.log" 2>&1 &
nos-lock-idle >/dev/null 2>&1 &

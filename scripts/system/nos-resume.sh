#!/usr/bin/env bash
set -euo pipefail

# Always bring outputs back before the locker redraws after resume.
hyprctl dispatch dpms on >/dev/null 2>&1 || true
hyprctl dispatch submap reset >/dev/null 2>&1 || true

if pgrep -u "$UID" -x hyprlock >/dev/null; then
  nos-lock-idle >/dev/null 2>&1 &
fi

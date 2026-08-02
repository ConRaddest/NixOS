#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
pid_file="$runtime_dir/nos-lock-idle.pid"

if [ -r "$pid_file" ]; then
  old_pid="$(cat "$pid_file")"
  if [ -n "$old_pid" ] && [ "$old_pid" != "$$" ]; then
    kill "$old_pid" >/dev/null 2>&1 || true
  fi
fi

printf '%s\n' "$$" >"$pid_file"
cleanup() {
  if [ -r "$pid_file" ] && [ "$(cat "$pid_file")" = "$$" ]; then
    rm -f "$pid_file"
  fi
}
trap cleanup EXIT INT TERM

# Fallback for locked-session idle. Some hypridle versions stop
# re-arming listeners after resume while ext-session-lock is active.
# If the user unlocks, hyprlock exits and this watcher becomes inert.
sleep 300
pgrep -u "$UID" -x hyprlock >/dev/null || exit 0
hyprctl dispatch dpms off >/dev/null 2>&1 || true

sleep 600
pgrep -u "$UID" -x hyprlock >/dev/null || exit 0
exec systemctl suspend

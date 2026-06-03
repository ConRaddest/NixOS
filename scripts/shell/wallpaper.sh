#!/usr/bin/env bash
# Sets the active wallpaper for all monitors.
# Called by the wallpaper picker with the chosen image path.
set -euo pipefail

wallpaper="${1:-}"

if [[ -z "$wallpaper" ]]; then
    echo "usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "wallpaper not found: $wallpaper" >&2
    exit 1
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nos"
current_wallpaper="$state_dir/current-wallpaper"

mkdir -p "$state_dir"
wallpaper="$(readlink -f "$wallpaper")"   # resolve to absolute path before symlinking
ln -sfn "$wallpaper" "$current_wallpaper"

# Reload hyprpaper with the new image. The preload step is required first —
# hyprpaper rejects a wallpaper path that hasn't been preloaded.
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 || true
    hyprctl hyprpaper wallpaper ",$wallpaper"
fi

#!/usr/bin/env bash
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
wallpaper="$(readlink -f "$wallpaper")"
ln -sfn "$wallpaper" "$current_wallpaper"

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl hyprpaper reload ,"$current_wallpaper" || true
fi

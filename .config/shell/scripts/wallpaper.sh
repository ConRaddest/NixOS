#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ───────────────────────────────────────────────────────────────────
wallpaper="${1:-}"

if [[ -z "$wallpaper" ]]; then
    echo "usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "wallpaper not found: $wallpaper" >&2
    exit 1
fi

# Resolve symlinks so the path stored in hyprpaper.nix is always absolute.
wallpaper="$(readlink -f "$wallpaper")"

# ─── Patch NixOS config ──────────────────────────────────────────────────────
# Replace the path in the let-binding line of hyprpaper.nix.
sed -i "s|^\(  wallpaper = \)\"[^\"]*\";|\1\"$wallpaper\";|" \
    "$HOME/OS/.config/hyprpaper/hyprpaper.nix"

# ─── Rebuild ─────────────────────────────────────────────────────────────────
# Run nos-refresh in a floating terminal (nixos-refresh window rule makes it float).
kitty --class nixos-refresh --title nixos-refresh -e bash -lic \
    "nos-refresh; echo; read -rp 'Press Enter to close...'" &
disown

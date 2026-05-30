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
# Replace the wallpaper path in hyprpaper.nix in-place.
sed -i "s|wallpaper = \"[^\"]*\";|wallpaper = \"$wallpaper\";|" \
    "$HOME/OS/.config/hyprpaper/hyprpaper.nix"

# ─── Rebuild ─────────────────────────────────────────────────────────────────
# Run home-manager switch in a visible terminal so the user can follow progress.
kitty --class nixos-refresh --title nixos-refresh -e bash -lc \
    "home-manager switch --flake \$HOME/OS#\$USER; echo; read -rp 'Press Enter to close...'" &
disown

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

wallpaper="$(readlink -f "$wallpaper")"

sed -i "s|wallpaper = \"[^\"]*\";|wallpaper = \"$wallpaper\";|" "$HOME/OS/config/hyprpaper.nix"

kitty --class nixos-refresh --title nixos-refresh -e bash -lc \
  "home-manager switch --flake \$HOME/OS#cdt; echo; read -rp 'Press Enter to close...'" &
disown

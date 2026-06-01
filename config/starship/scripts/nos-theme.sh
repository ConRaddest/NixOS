#!/usr/bin/env bash
set -euo pipefail

name="${1:-}"

themes_dir="$NOS_DIR/themes"

if [ -z "$name" ]; then
  find "$themes_dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort
  exit 0
fi

if [ ! -f "$themes_dir/${name}/theme.nix" ]; then
  printf 'Theme not found: %s\n\nAvailable themes:\n' "$name" >&2
  find "$themes_dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort >&2
  exit 1
fi

printf '\033[1;36mApplying theme: %s\033[0m\n\n' "$name"
ln -sf "${name}/theme.nix" "$themes_dir/current.nix"
nos-refresh

# Apply the theme's default wallpaper after rebuild
default_wallpaper=$(grep 'wallpaper = ' "$themes_dir/${name}/theme.nix" | head -1 | sed 's/.*"\(.*\)".*/\1/')
wallpaper_path="$themes_dir/$name/wallpapers/$default_wallpaper"
if [ -n "$default_wallpaper" ] && [ -f "$wallpaper_path" ]; then
  printf '\n\033[1;36mApplying wallpaper: %s\033[0m\n' "$default_wallpaper"
  bash "$NOS_DIR/config/shell/scripts/wallpaper.sh" "$wallpaper_path"
fi

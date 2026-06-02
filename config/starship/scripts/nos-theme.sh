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

printf '\n\033[1;36mRefreshing themed applications...\033[0m\n'
nautilus -q >/dev/null 2>&1 || true

# The GTK file picker is hosted by xdg-desktop-portal-gtk. It keeps GTK CSS in
# memory, but killing the portal while a picker is open can wedge clients like
# VS Code until they are restarted. Only refresh the portal backend when no
# picker window is currently mapped, and avoid killing xdg-desktop-portal itself.
file_picker_open=false
if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients 2>/dev/null | grep -qi 'xdg-desktop-portal-gtk'; then
    file_picker_open=true
  fi
fi

if [ "$file_picker_open" = true ]; then
  printf '\033[1;33mSkipping file picker portal refresh; close open file pickers and re-apply theme to refresh them.\033[0m\n'
else
  systemctl --user restart xdg-desktop-portal-gtk.service >/dev/null 2>&1 || true
fi

pkill -x btop >/dev/null 2>&1 || true

# Quickshell generates Theme.qml via Home Manager, so restart it to load the
# freshly-linked theme colors.
qs kill >/dev/null 2>&1 || true
sleep 0.2
if command -v uwsm >/dev/null 2>&1; then
  uwsm app -- qs >/dev/null 2>&1 &
else
  qs --daemonize >/dev/null 2>&1 || true
fi

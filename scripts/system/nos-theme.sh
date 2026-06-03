#!/usr/bin/env bash
# Switches the active theme and restarts affected applications.
# Usage: nos-theme [name]
#   No argument — list available themes.
#   name        — apply that theme and reload the desktop environment.
set -euo pipefail

name="${1:-}"
themes_dir="$NOS_DIR/themes"

# ─── List ─────────────────────────────────────────────────────────────────────
if [ -z "$name" ]; then
  find "$themes_dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort
  exit 0
fi

# ─── Validate ────────────────────────────────────────────────────────────────
if [ ! -f "$themes_dir/${name}/theme.nix" ]; then
  printf 'Theme not found: %s\n\nAvailable themes:\n' "$name" >&2
  find "$themes_dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort >&2
  exit 1
fi

# ─── Apply ───────────────────────────────────────────────────────────────────
printf '\033[1;36mApplying theme: %s\033[0m\n\n' "$name"

# current.nix is a relative symlink so the flake stays portable — it points to
# e.g. tokyo-night/theme.nix rather than an absolute path on this machine.
ln -sf "${name}/theme.nix" "$themes_dir/current.nix"
nos-refresh

# ─── Wallpaper ───────────────────────────────────────────────────────────────
# Extract the default wallpaper filename from the theme definition. The grep
# targets the first `wallpaper = "..."` assignment in theme.nix; sed strips
# the surrounding quotes.
default_wallpaper=$(grep 'wallpaper = ' "$themes_dir/${name}/theme.nix" | head -1 | sed 's/.*"\(.*\)".*/\1/')
wallpaper_path="$themes_dir/$name/wallpapers/$default_wallpaper"

if [ -n "$default_wallpaper" ] && [ -f "$wallpaper_path" ]; then
  printf '\n\033[1;36mApplying wallpaper: %s\033[0m\n' "$default_wallpaper"
  bash "$NOS_DIR/scripts/wallpaper.sh" "$wallpaper_path"
fi

# ─── Reload applications ─────────────────────────────────────────────────────
printf '\n\033[1;36mRefreshing themed applications...\033[0m\n'

# Nautilus caches its own icon theme; quitting it forces a clean reload on next open.
nautilus -q >/dev/null 2>&1 || true

# xdg-desktop-portal-gtk keeps GTK CSS in memory. Killing it while a file picker
# is open will wedge any client (e.g. VS Code) until it restarts, so we check
# first. We only restart the GTK backend, not xdg-desktop-portal itself.
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

# btop reads its color config at startup, so it must be restarted to pick up changes.
pkill -x btop >/dev/null 2>&1 || true

# Quickshell generates Theme.qml from the Nix-built home-manager output.
# Kill and relaunch so it loads the freshly-linked theme colors.
qs kill >/dev/null 2>&1 || true
sleep 0.2
if command -v uwsm >/dev/null 2>&1; then
  uwsm app -- qs >/dev/null 2>&1 &
else
  qs --daemonize >/dev/null 2>&1 || true
fi

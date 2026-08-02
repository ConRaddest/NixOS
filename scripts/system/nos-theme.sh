#!/usr/bin/env bash
# Switches the active theme and restarts affected applications.
# Usage: nos-theme [name]
#   No argument — list available themes.
#   name        — apply that theme and reload the desktop environment.
set -euo pipefail

# shellcheck source=scripts/system/progress.sh
source "$NOS_DIR/scripts/system/progress.sh"

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
nos_info "applying theme: $name..."

# current.nix is a relative symlink so the flake stays portable — it points to
# e.g. tokyo-night/theme.nix rather than an absolute path on this machine.
nos_stage "selecting theme..."
ln -sf "${name}/theme.nix" "$themes_dir/current.nix"

nos_stage "refreshing home-manager..."
nos-refresh

# ─── Wallpaper ───────────────────────────────────────────────────────────────
# Extract the default wallpaper filename from the theme definition. The grep
# targets the first `wallpaper = "..."` assignment in theme.nix; sed strips
# the surrounding quotes.
default_wallpaper=$(grep 'wallpaper = ' "$themes_dir/${name}/theme.nix" | head -1 | sed 's/.*"\(.*\)".*/\1/')
wallpaper_path="$themes_dir/$name/wallpapers/$default_wallpaper"

if [ -n "$default_wallpaper" ] && [ -f "$wallpaper_path" ]; then
  nos_stage "applying wallpaper..."
  bash "$NOS_DIR/scripts/shell/wallpaper.sh" "$wallpaper_path"
fi

# ─── Reload applications ─────────────────────────────────────────────────────
nos_stage "reloading applications..."

# KDE's portal owns file dialogs. Restart it under Hyprland so newly opened
# dialogs inherit refreshed settings, but never interrupt an open picker.
if [[ "${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]]; then
  file_picker_open=false
  if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl clients 2>/dev/null | grep -qi 'xdg-desktop-portal-kde'; then
      file_picker_open=true
    fi
  fi

  if [ "$file_picker_open" = true ]; then
    nos_info "skipping file picker portal refresh; close open file pickers and re-apply theme to refresh them."
  else
    systemctl --user restart xdg-desktop-portal-kde.service >/dev/null 2>&1 || true
  fi
fi

# btop reads its color config at startup, so it must be restarted to pick up changes.
pkill -x btop >/dev/null 2>&1 || true

nos_done

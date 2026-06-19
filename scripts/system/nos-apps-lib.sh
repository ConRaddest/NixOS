#!/usr/bin/env bash
set -euo pipefail

apps_file="${NOS_DIR:-$HOME/NixOS}/home/apps.nix"

write_apps_file() {
  local tmp packages
  tmp=$(mktemp)
  packages=$(mktemp)
  cat > "$tmp"

  sort -u "$tmp" > "$packages"

  cat > "$apps_file" <<'EOF'
# !!---------------------------------------------------!!
# !!---------- AUTO-GENERATED: Do not edit! -----------!!
# !!---------------------------------------------------!!

{ ... }:

{
  flake.lib.homeModules.apps =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
EOF

  sed '/^[[:space:]]*$/d; s/^/        /' "$packages" >> "$apps_file"

  cat >> "$apps_file" <<'EOF'
      ];
    };
}
EOF

  rm -f "$tmp" "$packages"
}

current_apps() {
  awk '
    /home\.packages = with pkgs; \[/ { in_list = 1; next }
    in_list && /\];/ { in_list = 0 }
    in_list {
      line = $0
      sub(/#.*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != "") print line
    }
  ' "$apps_file"
}

package_preview() {
  local attr="$1"
  nix eval --raw "nixpkgs#$attr.meta.description" 2>/dev/null || true
  printf '\n\n'
  nix eval --raw "nixpkgs#$attr.meta.homepage" 2>/dev/null || true
}

installed_apps() {
  local cache_dir cache now stamp
  cache_dir="${XDG_RUNTIME_DIR:-/tmp}/nos"
  cache="$cache_dir/installed-apps"
  mkdir -p "$cache_dir"

  now=$(date +%s)
  stamp=$(stat -c %Y "$cache" 2>/dev/null || printf 0)

  # The installed package set is queried from the current system and user
  # profiles. Cache briefly so every fzf keystroke does not traverse closures.
  if (( now - stamp < 300 )); then
    cat "$cache"
    return
  fi

  {
    current_apps

    paths=(/run/current-system/sw /etc/profiles/per-user/"$USER" "$HOME/.nix-profile")
    existing=()
    for path in "${paths[@]}"; do
      [[ -e "$path" ]] && existing+=("$path")
    done

    if ((${#existing[@]} > 0)); then
      nix-store -q --requisites "${existing[@]}" 2>/dev/null \
        | sed -E 's#.*/[a-z0-9]{32}-##; s/-[0-9].*$//' \
        | sed '/^[[:space:]]*$/d'
    fi
  } | sort -u > "$cache"

  cat "$cache"
}

search_apps() {
  local query="${1:-}"
  [[ -n "$query" ]] || return 0

  nix-search "$query" 2>/dev/null | awk -v installed="$(installed_apps | paste -sd ' ' -)" '
    BEGIN {
      split(installed, apps, " ")
      for (i in apps) installed_app[apps[i]] = 1
    }
    NF {
      name = $1
      if (installed_app[name]) next
      desc = $0
      sub(/^[^[:space:]]+[[:space:]]*/, "", desc)
      sub(/^@[[:space:]]*/, "", desc)
      print name "\t" desc
    }
  '
}

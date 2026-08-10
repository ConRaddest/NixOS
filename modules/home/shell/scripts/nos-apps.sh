#!/usr/bin/env bash
# Shared application-list and package-search helpers.
set -euo pipefail

# ╭──────────────────────────────────────────────────────────╮
# │ Configuration                                            │
# ╰──────────────────────────────────────────────────────────╯

nos_dir="${NOS_DIR:-$HOME/NixOS}"
NOS_DIR="$nos_dir"
# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$nos_dir/modules/home/shell/scripts/nos-ui.sh"
host_name=$(nos_host_name)
apps_file="$nos_dir/hosts/$host_name/apps.nix"

# ╭──────────────────────────────────────────────────────────╮
# │ Application List                                         │
# ╰──────────────────────────────────────────────────────────╯

write_apps_file() {
  local names tmp
  names=$(mktemp)
  tmp=$(mktemp --suffix=.nix)
  cat > "$names"

  if grep -Ev '^[a-zA-Z0-9][a-zA-Z0-9+._-]*(\.[a-zA-Z0-9][a-zA-Z0-9+._-]*)*$|^[[:space:]]*$' "$names" >&2; then
    printf 'Invalid Nixpkgs package attribute.\n' >&2
    rm -f "$names" "$tmp"
    return 1
  fi

  {
    printf '{ ... }:\n\n{\n  nos.apps = [\n'
    sed '/^[[:space:]]*$/d' "$names" | sort -u | while IFS= read -r attr; do
      printf '    "%s"\n' "$attr"
    done
    printf '  ];\n}\n'
  } > "$tmp"

  nixfmt "$tmp"
  mv "$tmp" "$apps_file"
  rm -f "$names"
}

current_apps() {
  sed -nE 's/^[[:space:]]*"([a-zA-Z0-9][a-zA-Z0-9+._-]*(\.[a-zA-Z0-9][a-zA-Z0-9+._-]*)*)"[[:space:]]*$/\1/p' "$apps_file"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Package Metadata                                         │
# ╰──────────────────────────────────────────────────────────╯

package_preview() {
  local attr="$1"
  nix eval --raw "nixpkgs#$attr.meta.description" 2>/dev/null || true
  printf '\n\n'
  nix eval --raw "nixpkgs#$attr.meta.homepage" 2>/dev/null || true
}

# ╭──────────────────────────────────────────────────────────╮
# │ Package Search                                           │
# ╰──────────────────────────────────────────────────────────╯

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

  nix-search "$query" 2>/dev/null | awk '
    NF {
      name = $1
      desc = $0
      sub(/^[^[:space:]]+[[:space:]]*/, "", desc)
      sub(/^@[[:space:]]*/, "", desc)
      print name "\t" desc
    }
  '
}

# ╭──────────────────────────────────────────────────────────╮
# │ Selection State                                          │
# ╰──────────────────────────────────────────────────────────╯

toggle_selected_app() {
  local file="$1"
  local attr="${2:-}"
  [[ -n "$attr" ]] || return 0

  touch "$file"
  if grep -Fxq -- "$attr" "$file"; then
    grep -Fvx -- "$attr" "$file" > "$file.tmp" || true
    mv "$file.tmp" "$file"
  else
    printf '%s\n' "$attr" >> "$file"
    sort -u -o "$file" "$file"
  fi
}

search_apps_with_selected_file() {
  local query="${1:-}"
  local selected_file="$2"

  touch "$selected_file"

  while IFS= read -r attr; do
    [[ -n "$attr" ]] && printf '%s\t[Selected]\tSelected: %s\n' "$attr" "$attr"
  done < "$selected_file"

  search_apps "$query" | awk -F '\t' -v selected_file="$selected_file" '
    BEGIN {
      while ((getline app < selected_file) > 0) selected_app[app] = 1
      close(selected_file)
    }
    NF && !selected_app[$1] { print $0 "\t  " $1 }
  '
}

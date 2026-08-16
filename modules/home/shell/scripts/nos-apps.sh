#!/usr/bin/env bash
# Shared application-list and package-search helpers.
set -euo pipefail

# ╭──────────────────────────────────────────────────────────╮
# │ Configuration                                            │
# ╰──────────────────────────────────────────────────────────╯

nos_dir="${NOS_DIR:-$HOME/NixOS}"
NOS_DIR="$nos_dir"
# shellcheck source=modules/home/shell/scripts/nos-ui.sh
# shellcheck disable=SC1091
source "$nos_dir/modules/home/shell/scripts/nos-ui.sh"
host_name=$(nos_host_name)
apps_file="$nos_dir/hosts/$host_name/apps.nix"
webapps_file="$nos_dir/hosts/$host_name/webapps.nix"

# ╭──────────────────────────────────────────────────────────╮
# │ Application List                                         │
# ╰──────────────────────────────────────────────────────────╯

write_apps_file() {
  local names tmp
  names=$(mktemp)
  tmp=$(mktemp --suffix=.nix)
  cat > "$names"

  if grep -Ev "^[a-zA-Z_][a-zA-Z0-9_'-]*(\.[a-zA-Z_][a-zA-Z0-9_'-]*)*$|^[[:space:]]*$" "$names" >&2; then
    printf 'Invalid Nixpkgs package attribute.\n' >&2
    rm -f "$names" "$tmp"
    return 1
  fi

  {
    printf '{ pkgs, ... }:\n\n{\n  home.packages = with pkgs; [\n'
    sed '/^[[:space:]]*$/d' "$names" | sort -u | while IFS= read -r attr; do
      printf '    %s\n' "$attr"
    done
    printf '  ];\n}\n'
  } > "$tmp"

  nixfmt "$tmp"
  mv "$tmp" "$apps_file"
  rm -f "$names"
}

current_apps() {
  sed -nE "s/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_'-]*(\.[a-zA-Z_][a-zA-Z0-9_'-]*)*)[[:space:]]*$/\1/p" "$apps_file"
}

current_webapps() {
  [[ -f "$webapps_file" ]] || return 0
  python3 - "$webapps_file" <<'PY'
import json
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
pattern = re.compile(
    r'^  \{\n'
    r'    id = ("(?:\\.|[^"\\])*");\n'
    r'    name = ("(?:\\.|[^"\\])*");\n'
    r'    url = ("(?:\\.|[^"\\])*");\n',
    re.MULTILINE,
)
for app_id, name, url in pattern.findall(text):
    print("\t".join((json.loads(app_id), json.loads(name), json.loads(url))))
PY
}

removable_apps() {
  while IFS= read -r attr; do
    printf 'package\t%s\t%s\n' "$attr" "$attr"
  done < <(current_apps)

  while IFS=$'\t' read -r app_id name _url; do
    printf 'webapp\t%s\t%s [Web App]\n' "$app_id" "$name"
  done < <(current_webapps)
}

remove_webapps() {
  [[ -f "$webapps_file" ]] || return 0
  python3 - "$webapps_file" "$@" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
remove = set(sys.argv[2:])
pattern = re.compile(
    r'^  \{\n'
    r'    id = ("(?:\\.|[^"\\])*");\n'
    r'(?:    .*\n)*?'
    r'  \}\n',
    re.MULTILINE,
)

def keep_or_remove(match):
    return "" if json.loads(match.group(1)) in remove else match.group(0)

path.write_text(pattern.sub(keep_or_remove, path.read_text()))
PY
}

# ╭──────────────────────────────────────────────────────────╮
# │ Package Metadata                                         │
# ╰──────────────────────────────────────────────────────────╯

package_preview() {
  local attr="$1" homepage
  nix eval --raw "nixpkgs#$attr.meta.description" 2>/dev/null || true
  printf '\n\n'

  homepage=$(nix eval --raw "nixpkgs#$attr.meta.homepage" 2>/dev/null || true)
  if [[ "$homepage" == http://* || "$homepage" == https://* ]]; then
    printf $'\e]8;;%s\e\\%s\e]8;;\e\\' "$homepage" "$homepage"
  else
    printf '%s' "$homepage"
  fi
}

removable_preview() {
  local entry_type="$1" entry_id="$2" app_id _name url
  if [[ "$entry_type" == package ]]; then
    package_preview "$entry_id"
    return
  fi

  while IFS=$'\t' read -r app_id _name url; do
    if [[ "$app_id" == "$entry_id" ]]; then
      printf 'Chromium web app\n\n%s\n' "$url"
      return
    fi
  done < <(current_webapps)
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

  nix-search --exact=false --json "$query" 2>/dev/null | jq -r '
    (. // [])[]
    | [(.path | sub("^nixpkgs\\."; "")), (.description // "")]
    | @tsv
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
  local selected_file="$NOS_SELECTED_FILE"

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

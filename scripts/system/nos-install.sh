#!/usr/bin/env bash
# Fuzzy NixOS package installer. Updates home/apps.nix, then rebuilds.
set -euo pipefail

# shellcheck source=scripts/system/nos-apps-lib.sh
source "${NOS_DIR:-$HOME/NixOS}/scripts/system/nos-apps-lib.sh"
# shellcheck source=scripts/system/progress.sh
source "${NOS_DIR:-$HOME/NixOS}/scripts/system/progress.sh"

reload_cmd='bash -lc '\''source "$NOS_DIR/scripts/system/nos-apps-lib.sh"; search_apps "$1"'\'' _ {q}'

fzf_args=(
  --multi
  --disabled
  --delimiter $'\t'
  --with-nth 1
  --preview 'bash -lc '\''printf "%s\n\n" "$1"; source "$NOS_DIR/scripts/system/nos-apps-lib.sh"; package_preview "$2"'\'' _ {2} {1}'
  --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:35%:wrap'
  --bind "start:reload:$reload_cmd"
  --bind "change:reload:sleep 0.3; $reload_cmd"
  --bind 'ctrl-c:clear-query+clear-selection'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
)

initial_query="$*"
selections=$(fzf --query "$initial_query" "${fzf_args[@]}")
pkg_names=$(printf '%s\n' "${selections:-}" | cut -f1 | sed '/^[[:space:]]*$/d')

if [[ -n "${pkg_names:-}" ]]; then
  { current_apps; printf '%s\n' "$pkg_names"; } | write_apps_file
  set +e
  nos-build
  status=$?
  set -e
  nos_press_enter_to_close
  exit "$status"
fi

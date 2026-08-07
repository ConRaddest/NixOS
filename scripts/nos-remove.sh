#!/usr/bin/env bash
# Fuzzy Home Manager package remover. Updates home/apps.nix, then refreshes Home Manager.
set -euo pipefail

# shellcheck source=scripts/nos-apps-lib.sh
source "${NOS_DIR:-$HOME/NixOS}/scripts/nos-apps-lib.sh"

fzf_args=(
  --multi
  --preview 'bash -lc '\''source "$NOS_DIR/scripts/nos-apps-lib.sh"; package_preview {1}'\'''
  --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:35%:wrap'
  --bind 'ctrl-c:clear-query+clear-selection'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
)

pkg_names=$(current_apps | fzf "${fzf_args[@]}")

if [[ -n "${pkg_names:-}" ]]; then
  grep -Fvx -f <(printf '%s\n' "$pkg_names") <(current_apps) | write_apps_file
  exec nos-refresh
fi

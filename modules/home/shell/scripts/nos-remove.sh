#!/usr/bin/env bash
# Remove packages from the selected host application list.
set -euo pipefail

# shellcheck source=modules/home/shell/scripts/nos-apps.sh
source "${NOS_DIR:-$HOME/NixOS}/modules/home/shell/scripts/nos-apps.sh"

nos_wordmark

# ╭──────────────────────────────────────────────────────────╮
# │ Interface                                                │
# ╰──────────────────────────────────────────────────────────╯

fzf_args=(
  --multi
  --preview 'bash -lc '\''source "$NOS_DIR/modules/home/shell/scripts/nos-apps.sh"; package_preview {1}'\'''
  --preview-label='Tab: Select · Enter: Remove · Alt-P: Preview · Alt-J/K: Scroll'
  --preview-label-pos='bottom'
  --preview-window 'down:35%:wrap'
  --bind 'ctrl-c:clear-query+clear-selection'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
)

# ╭──────────────────────────────────────────────────────────╮
# │ Main                                                     │
# ╰──────────────────────────────────────────────────────────╯

while true; do
  if ! pkg_names=$(current_apps | fzf "${fzf_args[@]}"); then
    exit 0
  fi

  [[ -n "${pkg_names:-}" ]] || continue
  { grep -Fvx -f <(printf '%s\n' "$pkg_names") <(current_apps) || true; } | write_apps_file

  if ! nos-refresh; then
    printf '\nRemove refresh failed.\n'
    exit 1
  fi

  break
done

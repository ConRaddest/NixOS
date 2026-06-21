#!/usr/bin/env bash
# Fuzzy NixOS package installer. Updates home/apps.nix, then rebuilds.
set -euo pipefail

# shellcheck source=scripts/system/nos-apps-lib.sh
source "${NOS_DIR:-$HOME/NixOS}/scripts/system/nos-apps-lib.sh"
# shellcheck source=scripts/system/progress.sh
source "${NOS_DIR:-$HOME/NixOS}/scripts/system/progress.sh"

selected_file=$(mktemp)
trap 'rm -f "$selected_file"' EXIT
selected_file_q=$(printf '%q' "$selected_file")

reload_cmd='bash -lc '\''source "$NOS_DIR/scripts/system/nos-apps-lib.sh"; search_apps_with_selected_file "$1" "$2"'\'' _ {q} '"$selected_file_q"
toggle_cmd='bash -lc '\''source "$NOS_DIR/scripts/system/nos-apps-lib.sh"; toggle_selected_app "$1" "$2"'\'' _ '"$selected_file_q"' {1}'
toggle_action_cmd='bash -lc '\''[[ "$1" == "[selected]" ]] && echo exclude || echo toggle'\'' _ {2}'

fzf_args=(
  --multi
  --disabled
  --delimiter $'\t'
  --with-nth 3
  --track
  --id-nth 1
  --preview 'bash -lc '\''printf "%s\n\n" "$1"; source "$NOS_DIR/scripts/system/nos-apps-lib.sh"; package_preview "$2"'\'' _ {2} {1}'
  --preview-label='tab: select/remove, enter: install selected, alt-p: preview, alt-j/k: scroll'
  --preview-label-pos='bottom'
  --preview-window 'down:35%:wrap'
  --bind "start:reload:$reload_cmd"
  --bind "change:reload:sleep 0.3; $reload_cmd"
  --bind "tab:execute-silent($toggle_cmd)+transform($toggle_action_cmd)"
  --bind "shift-tab:execute-silent($toggle_cmd)+transform($toggle_action_cmd)"
  --bind 'ctrl-c:clear-query'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
)

initial_query="$*"
selection=$(fzf --query "$initial_query" "${fzf_args[@]}")
selected_count=$(sed '/^[[:space:]]*$/d' "$selected_file" | wc -l)

if (( selected_count > 0 )); then
  pkg_names=$(sed '/^[[:space:]]*$/d' "$selected_file")
else
  pkg_names=$(printf '%s\n' "${selection:-}" | cut -f1 | sed '/^[[:space:]]*$/d')
fi

if [[ -n "${pkg_names:-}" ]]; then
  { current_apps; printf '%s\n' "$pkg_names"; } | write_apps_file
  exec nos-build
fi

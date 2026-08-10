#!/usr/bin/env bash
# Add packages to the selected host application list.
set -euo pipefail

# shellcheck source=modules/home/shell/scripts/nos-apps.sh
source "${NOS_DIR:-$HOME/NixOS}/modules/home/shell/scripts/nos-apps.sh"

nos_wordmark

# ╭──────────────────────────────────────────────────────────╮
# │ Selection State                                          │
# ╰──────────────────────────────────────────────────────────╯

selected_file=$(mktemp)
trap 'rm -f "$selected_file"' EXIT
selected_file_q=$(printf '%q' "$selected_file")

reload_cmd='bash -lc '\''source "$NOS_DIR/modules/home/shell/scripts/nos-apps.sh"; search_apps_with_selected_file "${1// /-}" "$2"'\'' _ {q} '"$selected_file_q"
toggle_cmd='bash -lc '\''source "$NOS_DIR/modules/home/shell/scripts/nos-apps.sh"; toggle_selected_app "$1" "$2"'\'' _ '"$selected_file_q"' {1}'
toggle_action_cmd='bash -lc '\''[[ "$1" == "[Selected]" ]] && echo exclude || echo toggle'\'' _ {2}'

# ╭──────────────────────────────────────────────────────────╮
# │ Interface                                                │
# ╰──────────────────────────────────────────────────────────╯

fzf_args=(
  --multi
  --disabled
  --delimiter $'\t'
  --with-nth 3
  --track
  --id-nth 1
  --preview 'bash -lc '\''printf "%s\n\n" "$1"; source "$NOS_DIR/modules/home/shell/scripts/nos-apps.sh"; package_preview "$2"'\'' _ {2} {1}'
  --preview-label='Tab: Select/remove · Enter: Install · Alt-P: Preview · Alt-J/K: Scroll'
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

# ╭──────────────────────────────────────────────────────────╮
# │ Main                                                     │
# ╰──────────────────────────────────────────────────────────╯

initial_query="$*"
while true; do
  : > "$selected_file"

  if ! selection=$(fzf --query "$initial_query" "${fzf_args[@]}"); then
    exit 0
  fi
  initial_query=""

  selected_count=$(sed '/^[[:space:]]*$/d' "$selected_file" | wc -l)
  if (( selected_count > 0 )); then
    pkg_names=$(sed '/^[[:space:]]*$/d' "$selected_file")
  else
    pkg_names=$(printf '%s\n' "${selection:-}" | cut -f1 | sed '/^[[:space:]]*$/d')
  fi

  [[ -n "${pkg_names:-}" ]] || continue
  { current_apps; printf '\n%s\n' "$pkg_names"; } | write_apps_file

  if ! NOS_COMMIT_MESSAGE="apps: update $host_name packages" nos-refresh; then
    printf '\nInstall refresh failed. Press Enter to close.\n'
    read -r
    exit 1
  fi
done

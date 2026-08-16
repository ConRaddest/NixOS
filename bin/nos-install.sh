#!/usr/bin/env bash
# Add packages to the selected host application list.
set -euo pipefail

export NOS_RUNTIME_DIR="${NOS_RUNTIME_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=bin/nos-packages.sh
source "$NOS_RUNTIME_DIR/nos-packages.sh"
nos_operation_lock

nos_wordmark "Installing Applications"

# ╭──────────────────────────────────────────────────────────╮
# │ Selection State                                          │
# ╰──────────────────────────────────────────────────────────╯

selected_file=$(mktemp)
apps_backup=$(mktemp)
cp -- "$apps_file" "$apps_backup"
cleanup() {
  local status=$?
  if ((status != 0)); then
    cp -- "$apps_backup" "$apps_file"
  fi
  rm -f -- "$selected_file" "$apps_backup"
  return "$status"
}
trap cleanup EXIT
selected_file_q=$(printf '%q' "$selected_file")

# shellcheck disable=SC2016 # Inner shell expands positional parameters.
reload_cmd='NOS_SELECTED_FILE='"$selected_file_q"' bash -lc '\''source "$NOS_RUNTIME_DIR/nos-packages.sh"; search_apps_with_selected_file "$1"'\'' _ {q}'
# shellcheck disable=SC2016 # Inner shell expands positional parameters.
toggle_cmd='bash -lc '\''source "$NOS_RUNTIME_DIR/nos-packages.sh"; toggle_selected_app "$1" "$2"'\'' _ '"$selected_file_q"' {1}'
# shellcheck disable=SC2016 # Inner shell expands positional parameters.
toggle_action_cmd='bash -lc '\''[[ "$1" == "[Selected]" ]] && echo exclude || echo toggle'\'' _ {2}'

# ╭──────────────────────────────────────────────────────────╮
# │ Interface                                                │
# ╰──────────────────────────────────────────────────────────╯

# shellcheck disable=SC2016 # Inner shell expands preview parameters.
fzf_args=(
  --multi
  --delimiter $'\t'
  --with-nth 3
  --track
  --id-nth 1
  --preview 'bash -lc '\''source "$NOS_RUNTIME_DIR/nos-packages.sh"; package_preview "$1"'\'' _ {1}'
  --preview-label='Tab: Select/remove · Enter: Install · Alt-P: Preview · Alt-J/K: Scroll'
  --preview-label-pos='bottom'
  --preview-window 'down:35%:wrap'
  --bind "start:reload:$reload_cmd"
  --bind "change:reload:sleep 0.5; $reload_cmd"
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

  if ! nos switch; then
    printf '\nInstall switch failed.\n'
    exit 1
  fi

  break
done

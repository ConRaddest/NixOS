#!/usr/bin/env bash
# Remove packages from the selected host application list.
set -euo pipefail

export NOS_RUNTIME_DIR="${NOS_RUNTIME_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=bin/nos-packages.sh
source "$NOS_RUNTIME_DIR/nos-packages.sh"
nos_operation_lock

nos_wordmark "Removing Applications"

apps_backup=$(mktemp)
cp -- "$apps_file" "$apps_backup"
cleanup() {
  local status=$?
  if ((status != 0)); then
    cp -- "$apps_backup" "$apps_file"
  fi
  rm -f -- "$apps_backup"
  return "$status"
}
trap cleanup EXIT

# ╭──────────────────────────────────────────────────────────╮
# │ Interface                                                │
# ╰──────────────────────────────────────────────────────────╯

# shellcheck disable=SC2016 # Inner shell expands preview parameters.
fzf_args=(
  --multi
  --delimiter $'\t'
  --with-nth 3
  --preview 'bash -lc '\''source "$NOS_RUNTIME_DIR/nos-packages.sh"; removable_preview "$1" "$2"'\'' _ {1} {2}'
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
  if ! selections=$(removable_apps | fzf "${fzf_args[@]}"); then
    exit 0
  fi

  [[ -n "${selections:-}" ]] || continue
  package_names=$(printf '%s\n' "$selections" | awk -F '\t' '$1 == "package" { print $2 }')
  mapfile -t webapp_ids < <(printf '%s\n' "$selections" | awk -F '\t' '$1 == "webapp" { print $2 }')

  if [[ -n "$package_names" ]]; then
    { grep -Fvx -f <(printf '%s\n' "$package_names") <(current_apps) || true; } | write_apps_file
  fi
  ((${#webapp_ids[@]} == 0)) || remove_webapps "${webapp_ids[@]}"

  if ! nos switch; then
    printf '\nRemove switch failed.\n'
    exit 1
  fi

  break
done

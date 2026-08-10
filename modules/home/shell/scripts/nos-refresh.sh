#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nos_operation_terminal "refresh" "Home Manager Refresh" "$@"

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

stage_changes() {
  git -C "$NOS_DIR" add -A
}

run_refresh() {
  local host_name

  nos_wordmark "Switching Home Manager" || return
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && stage_changes \
    && nos_run home-manager switch "${nix_opts[@]}" --flake "$NOS_DIR#$USER@$host_name"
}

run_refresh

#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

commit_changes() {
  git -C "$NOS_DIR" add -A

  if ! git -C "$NOS_DIR" diff --cached --quiet; then
    git -C "$NOS_DIR" commit -m "${NOS_COMMIT_MESSAGE:-chore: refresh configuration}"
  fi
}

run_refresh() {
  local host_name

  nos_wordmark || return
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && commit_changes \
    && nos_run home-manager switch "${nix_opts[@]}" --flake "$NOS_DIR#$USER@$host_name"
}

nos_begin "refresh"
if nos_capture run_refresh; then
  nos_finish "success" "Home Manager Refresh Finished" "Configuration applied successfully."
else
  nos_finish "failure" "Home Manager Refresh Failed" "Configuration was not applied."
  exit 1
fi

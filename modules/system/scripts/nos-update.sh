#!/usr/bin/env bash
# Updates all flake inputs to their latest versions, then rebuilds and switches.
# Sequence: format → update lockfile → rebuild.
#
# set -uo rather than -euo: run_update uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

run_update() {
  local host_name
  host_name=$(nos_host_name)

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_stage "updating system" \
    && nos_run nix flake update --option warn-dirty false --flake "path:$NOS_DIR" \
    && nos_stage "building system" \
    && nos_run sudo nixos-rebuild switch --option warn-dirty false --flake "path:$NOS_DIR#$host_name" \
    && nos_done
}

while true; do
  if run_update; then
    exit 0
  fi

  nos_fail "update failed"
  nos_retry_prompt
  read -r -n 1 answer
  printf '\n'
  case "$answer" in
    ''|y|Y) ;;
    *) exit 1 ;;
  esac
done

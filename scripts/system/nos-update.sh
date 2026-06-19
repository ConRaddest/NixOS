#!/usr/bin/env bash
# Updates all flake inputs to their latest versions, then rebuilds and switches.
# Sequence: format → stage source → update lockfile → stage lockfile → rebuild.
#
# flake.lock is staged in a separate git-add call because it is written by
# `nix flake update`, not by us, and must be picked up after that step.
#
# set -uo rather than -euo: run_update uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# shellcheck source=scripts/system/progress.sh
source "$NOS_DIR/scripts/system/progress.sh"

run_update() {
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && git -C "$NOS_DIR" add . \
    && nos_stage "updating system..." \
    && nos_run nix flake update --option warn-dirty false --flake "$NOS_DIR" \
    && nos_stage "staging lockfile..." \
    && git -C "$NOS_DIR" add flake.lock \
    && nos_stage "building system..." \
    && nos_run sudo nixos-rebuild switch --option warn-dirty false --flake "$NOS_DIR#$HOSTNAME" \
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
  printf '\n'
done

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

run_update() {
  printf '\033[1;36mUpdating system to latest packages...\033[0m\n\n'

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt \
    && git -C "$NOS_DIR" add . \
    && nix flake update --flake "$NOS_DIR" \
    && git -C "$NOS_DIR" add flake.lock \
    && sudo nixos-rebuild switch --flake "$NOS_DIR#$HOSTNAME"
}

while true; do
  if run_update; then
    exit 0
  fi

  printf '\n\033[1;31mSomething went wrong... Would you like to retry? [Y/n]\033[0m '
  read -r -n 1 answer
  printf '\n'
  case "$answer" in
    y|Y) ;;
    *) exit 1 ;;
  esac
  printf '\n'
done

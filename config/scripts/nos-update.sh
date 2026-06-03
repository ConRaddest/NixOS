#!/usr/bin/env bash
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

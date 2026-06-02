#!/usr/bin/env bash
set -uo pipefail

offline=""
if [[ "${1:-}" == "--offline" ]]; then
  offline="--option substitute false"
fi

run_refresh() {
  printf '\033[1;36mSyncing home manager configuration...\033[0m\n\n'
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt \
    && git -C "$NOS_DIR" add . \
    && home-manager switch $offline --flake "$NOS_DIR#$USER"
}

while true; do
  if run_refresh; then
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

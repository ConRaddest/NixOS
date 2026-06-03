#!/usr/bin/env bash
# Formats all Nix files, stages them, then runs home-manager switch.
# Pass --offline to build from the local Nix store only (no downloads).
#
# set -uo rather than -euo: run_refresh uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# Use an array so the offline flag expands cleanly as separate words,
# and expands to nothing at all when not set.
offline_opts=()
if [[ "${1:-}" == "--offline" ]]; then
  offline_opts=(--option substitute false)
fi

run_refresh() {
  printf '\033[1;36mSyncing home manager configuration...\033[0m\n\n'

  # Format and stage first so the applied configuration matches the source tree
  # and the git index is clean for inspection after a successful switch.
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt \
    && git -C "$NOS_DIR" add . \
    && home-manager switch "${offline_opts[@]}" --flake "$NOS_DIR#$USER"
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

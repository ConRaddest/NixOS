#!/usr/bin/env bash
# Formats all Nix files, stages them, then runs nixos-rebuild switch.
# Pass --offline to build from the local Nix store only (no downloads).
#
# set -uo rather than -euo: run_build uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# shellcheck source=scripts/system/progress.sh
source "$NOS_DIR/scripts/system/progress.sh"

# Use an array so the offline flag expands cleanly as separate words,
# and expands to nothing at all when not set.
offline_opts=()
if [[ "${1:-}" == "--offline" ]]; then
  offline_opts=(--option substitute false)
fi

run_build() {
  printf '\033[1;36mBuilding and switching system configuration...\033[0m\n'

  # Format and stage first so the built configuration matches the source tree
  # and the git index is clean for inspection after a successful build.
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && git -C "$NOS_DIR" add . \
    && nos_stage "switch nixos" \
    && sudo nixos-rebuild switch "${offline_opts[@]}" --flake "$NOS_DIR#$HOSTNAME" \
    && nos_done
}

while true; do
  if run_build; then
    exit 0
  fi

  nos_fail "build failed"
  printf '\n\033[1;31mSomething went wrong... Would you like to retry? [Y/n]\033[0m '
  read -r -n 1 answer
  printf '\n'
  case "$answer" in
    y|Y) ;;
    *) exit 1 ;;
  esac
  printf '\n'
done

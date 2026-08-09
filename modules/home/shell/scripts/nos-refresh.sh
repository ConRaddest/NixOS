#!/usr/bin/env bash
# Formats all Nix files, stages them, then runs home-manager switch.
# Pass --offline to build from the local Nix store only (no downloads).
#
# set -uo rather than -euo: run_refresh uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

# Use an array so the offline flag expands cleanly as separate words,
# and expands to nothing at all when not set.
nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

run_refresh() {
  local host_name profile
  host_name=$(nos_host_name)
  profile="$USER@$host_name"

  # Format and stage first so the applied configuration matches the source tree
  # and the git index is clean for inspection after a successful switch.
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && git -C "$NOS_DIR" add . \
    && nos_stage "switching home manager" \
    && nos_run home-manager switch "${nix_opts[@]}" --flake "$NOS_DIR#$profile" \
    && nos_done
}

while true; do
  if run_refresh; then
    nos_repeat_prompt
    read -r -n 1 answer
    printf '\n'
    [[ "$answer" =~ ^[yY]$ ]] || exit 0
  else
    nos_fail "refresh failed"
    nos_retry_prompt
    read -r -n 1 answer
    printf '\n'
    case "$answer" in
      ''|y|Y) ;;
      *) exit 1 ;;
    esac
  fi
done

#!/usr/bin/env bash
# Formats all Nix files, then runs nixos-rebuild switch from the working tree.
# Pass --offline to build from the local Nix store only (no downloads).
#
# set -uo rather than -euo: run_build uses && chaining to catch failures,
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

run_build() {
  local host_name
  host_name=$(nos_host_name)

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_stage "building system" \
    && nos_run sudo nixos-rebuild switch "${nix_opts[@]}" --flake "path:$NOS_DIR#$host_name" \
    && nos_done
}

while true; do
  if run_build; then
    nos_repeat_prompt
    read -r -n 1 answer
    printf '\n'
    [[ "$answer" =~ ^[yY]$ ]] || exit 0
  else
    nos_fail "build failed"
    nos_retry_prompt
    read -r -n 1 answer
    printf '\n'
    case "$answer" in
      ''|y|Y) ;;
      *) exit 1 ;;
    esac
  fi
done

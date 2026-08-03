#!/usr/bin/env bash
# Formats all Nix files, stages them, then runs home-manager switch.
# Pass --offline to build from the local Nix store only (no downloads).
#
# set -uo rather than -euo: run_refresh uses && chaining to catch failures,
# and the loop must stay alive after a failure to offer the retry prompt.
set -uo pipefail

# shellcheck source=scripts/system/nos-ui.sh
source "$NOS_DIR/scripts/system/nos-ui.sh"

# Use an array so the offline flag expands cleanly as separate words,
# and expands to nothing at all when not set.
nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

run_refresh() {
  # Format and stage first so the applied configuration matches the source tree
  # and the git index is clean for inspection after a successful switch.
  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && git -C "$NOS_DIR" add . \
    && nos_stage "Refreshing Home Manager configuration" \
    && nos_run home-manager switch "${nix_opts[@]}" --flake "$NOS_DIR#$USER" \
    && nos_stage "Restarting desktop shell" \
    && restart_desktop_shell \
    && nos_done
}

restart_desktop_shell() {
  case "${NOS_DESKTOP_SHELL:-none}" in
    dms) systemctl --user restart dms.service ;;
    none) ;;
    *) nos_fail "Unsupported desktop shell: ${NOS_DESKTOP_SHELL}"; return 1 ;;
  esac
}

while true; do
  if run_refresh; then
    nos_repeat_prompt
    read -r -n 1 answer
    printf '\n'
    [[ "$answer" =~ ^[rR]$ ]] || exit 0
    printf '\n'
  else
    nos_fail "Refresh failed"
    nos_retry_prompt
    read -r -n 1 answer
    printf '\n'
    case "$answer" in
      ''|y|Y) ;;
      *) exit 1 ;;
    esac
    printf '\n'
  fi
done

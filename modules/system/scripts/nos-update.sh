#!/usr/bin/env bash
# Update flake inputs and rebuild the selected NixOS host.
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

# ╭──────────────────────────────────────────────────────────╮
# │ Update                                                   │
# ╰──────────────────────────────────────────────────────────╯

run_update() {
  local host_name
  host_name=$(nos_host_name)

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_stage "Updating Flake Inputs" \
    && nos_run nix flake update --option warn-dirty false --flake "$NOS_DIR" \
    && printf '\n' \
    && nos_stage "Building Updated NixOS Configuration" \
    && nos_run sudo nixos-rebuild switch --option warn-dirty false --flake "$NOS_DIR#$host_name" \
    && printf '\n' \
    && nos_done "Flake inputs updated and NixOS configuration applied successfully."
}

# ╭──────────────────────────────────────────────────────────╮
# │ Main                                                     │
# ╰──────────────────────────────────────────────────────────╯

while true; do
  if run_update; then
    exit 0
  fi

  nos_fail "Update or rebuild failed."
  nos_retry_prompt
  read -r -n 1 answer
  printf '\n\n'
  case "$answer" in
    ''|y|Y) ;;
    *) exit 1 ;;
  esac
done

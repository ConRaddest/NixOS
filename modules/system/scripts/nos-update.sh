#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

run_update() {
  local host_name
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_run nix flake update --flake "$NOS_DIR" \
    && nos_run sudo --askpass nixos-rebuild switch --flake "$NOS_DIR#$host_name"
}

nos_begin "update"
if nos_capture run_update; then
  nos_finish "success" "NixOS Update Finished" "Inputs updated and configuration applied successfully."
else
  nos_finish "failure" "NixOS Update Failed" "Update or rebuild failed."
  exit 1
fi

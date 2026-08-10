#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nos_operation_terminal "update" "NixOS Update" "$@"

run_update() {
  local host_name

  nos_wordmark "Updating System Configuration" || return
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_run nix flake update --flake "$NOS_DIR" \
    && nos_run sudo --askpass nixos-rebuild switch --flake "$NOS_DIR#$host_name"
}

run_update

#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

run_build() {
  local host_name
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_run sudo --askpass nixos-rebuild switch "${nix_opts[@]}" --flake "$NOS_DIR#$host_name"
}

nos_begin "build"
if nos_capture run_build; then
  nos_finish "success" "NixOS Build Finished" "Configuration applied successfully."
else
  nos_finish "failure" "NixOS Build Failed" "Configuration was not applied."
  exit 1
fi

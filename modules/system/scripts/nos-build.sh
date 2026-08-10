#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nos_operation_terminal "build" "NixOS Build" "$@"

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

run_build() {
  local host_name

  nos_wordmark || return
  host_name=$(nos_host_name) || return

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_run sudo --askpass nixos-rebuild switch "${nix_opts[@]}" --flake "$NOS_DIR#$host_name"
}

run_build

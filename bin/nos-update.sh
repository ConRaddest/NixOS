#!/usr/bin/env bash
set -uo pipefail

export NOS_RUNTIME_DIR="${NOS_RUNTIME_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=bin/nos-ui.sh
source "$NOS_RUNTIME_DIR/nos-ui.sh"

nos_operation_terminal "update" "NixOS Update" "$@"
nos_operation_lock

run_update() {
  local host_name result system_path
  local -a changed_files=()

  nos_wordmark "Updating System Configuration" || return
  host_name=$(nos_host_name) || return
  nos_require_tracked_nix_files || return
  mapfile -d '' -t changed_files < <(nos_changed_nix_files)
  [[ ! -f "$NOS_DIR/flake.lock" ]] || changed_files+=("flake.lock")
  nos_transaction_begin "${changed_files[@]}"
  trap nos_transaction_restore EXIT

  nos_format_changed_nix || return
  nos_run nix flake update --flake "$NOS_DIR" || return
  result="$NOS_TRANSACTION_DIR/system"
  nos_run nix build --out-link "$result" \
    "$NOS_DIR#nixosConfigurations.$host_name.config.system.build.toplevel" || return
  system_path=$(readlink -f "$result") || return
  nos_run sudo nix-env \
    --profile /nix/var/nix/profiles/system \
    --set "$system_path" || return
  nos_run sudo "$system_path/bin/switch-to-configuration" switch || return

  nos_transaction_finish
  trap - EXIT
}

run_update

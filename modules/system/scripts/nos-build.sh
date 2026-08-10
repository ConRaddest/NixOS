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
  local host_name result system_path
  local -a changed_files=()

  nos_wordmark "Rebuilding System Configuration" || return
  host_name=$(nos_host_name) || return
  nos_require_tracked_nix_files || return
  mapfile -d '' -t changed_files < <(nos_changed_nix_files)
  nos_transaction_begin "${changed_files[@]}"
  trap nos_transaction_restore EXIT

  nos_format_changed_nix || return
  result="$NOS_TRANSACTION_DIR/system"
  nos_run nix build "${nix_opts[@]}" --out-link "$result" \
    "$NOS_DIR#nixosConfigurations.$host_name.config.system.build.toplevel" || return
  system_path=$(readlink -f "$result") || return
  nos_run sudo nix-env \
    --profile /nix/var/nix/profiles/system \
    --set "$system_path" || return
  nos_run sudo "$system_path/bin/switch-to-configuration" switch || return

  nos_transaction_finish
  trap - EXIT
}

run_build

#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

nos_operation_terminal "refresh" "Home Manager Refresh" "$@"

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

run_refresh() {
  local host_name result
  local -a changed_files=()

  nos_wordmark "Switching Home Manager" || return
  host_name=$(nos_host_name) || return
  nos_require_tracked_nix_files || return
  mapfile -d '' -t changed_files < <(nos_changed_nix_files)
  nos_transaction_begin "${changed_files[@]}"
  trap nos_transaction_restore EXIT

  nos_format_changed_nix || return
  result="$NOS_TRANSACTION_DIR/home-manager"
  nos_run nix build "${nix_opts[@]}" --out-link "$result" \
    "$NOS_DIR#homeConfigurations.\"$USER@$host_name\".activationPackage" || return
  "$result/activate" || return

  nos_transaction_finish
  trap - EXIT
}

run_refresh

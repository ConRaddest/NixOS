#!/usr/bin/env bash
# Shared presentation helpers for nos-* scripts.
# Intentionally does not capture command output: build/update logs stay visible.

if [ -t 1 ]; then
  nos_accent=$'\033[38;5;141m'
  nos_dim=$'\033[38;5;60m'
  nos_ok=$'\033[38;5;120m'
  nos_err=$'\033[38;5;203m'
  nos_bold=$'\033[1m'
  nos_reset=$'\033[0m'
else
  nos_accent=''
  nos_dim=''
  nos_ok=''
  nos_err=''
  nos_bold=''
  nos_reset=''
fi

nos_stage() {
  local label="$1"
  NOS_STAGE_STARTED=1
  NOS_STAGE_HAD_OUTPUT=0
  printf '%s%s%s%s\n\n' "$nos_bold" "$nos_accent" "$label" "$nos_reset"
}

nos_done() {
  if [[ "${NOS_STAGE_HAD_OUTPUT:-0}" == 1 ]]; then
    printf '\n'
  fi
  printf '%s✓ done%s\n' "$nos_ok" "$nos_reset"
}

nos_run() {
  NOS_STAGE_HAD_OUTPUT=1

  # Keep stdout/stderr attached to the terminal. Piping through awk/sed makes
  # nix/home-manager think they are not running on a TTY, which disables their
  # default coloured output. Suppress dirty-flake warnings via Nix config
  # instead of filtering the output stream.
  local nix_config="${NIX_CONFIG:-}"
  if [[ -n "$nix_config" ]]; then
    nix_config+=$'\n'
  fi
  nix_config+='warn-dirty = false'

  NIX_CONFIG="$nix_config" "$@"
}

nos_info() {
  local label="$1"
  printf '%s%s%s\n' "$nos_accent" "$label" "$nos_reset"
}

nos_fail() {
  local label="${1:-failed}"
  printf '\n%s✗ %s%s\n' "$nos_err" "$label" "$nos_reset" >&2
}

nos_retry_prompt() {
  printf '\n%sSomething went wrong... Would you like to retry? [Y/n]%s ' "$nos_err" "$nos_reset"
}

nos_repeat_prompt() {
  printf '\n%sEnter%s → Close  %sR%s → Repeat  ' "$nos_accent" "$nos_reset" "$nos_accent" "$nos_reset"
}

nos_press_enter_to_close() {
  printf '\n%sPress Enter to close...%s' "$nos_accent" "$nos_reset"
  read -r
}

# Backward-compatible shims for older installed nos-* wrappers that still call
# the previous progress API while sourcing this live helper from $NOS_DIR.
progress_init() { :; }
progress_done() { nos_done; }
progress_fail() { nos_fail "$@"; }
progress_step() { nos_stage "$@"; }

run_step() {
  local label="$1"
  shift

  # Older weighted callers use: run_step "label" 10 command ...
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    shift
  fi

  nos_stage "$label"
  nos_run "$@"
}

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
  printf '\n%s%s╭─ %s%s\n' "$nos_bold" "$nos_accent" "$label" "$nos_reset"
  printf '%s╰────────────────────────────────────────%s\n' "$nos_dim" "$nos_reset"
}

nos_done() {
  printf '\n%s✓ done%s\n' "$nos_ok" "$nos_reset"
}

nos_fail() {
  local label="${1:-failed}"
  printf '\n%s✗ %s%s\n' "$nos_err" "$label" "$nos_reset" >&2
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
  "$@"
}

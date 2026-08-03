#!/usr/bin/env bash
# Shared terminal output helpers for nos-* scripts.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly NOS_ACCENT=$'\033[38;5;141m'
  readonly NOS_OK=$'\033[38;5;120m'
  readonly NOS_ERROR=$'\033[38;5;203m'
  readonly NOS_BOLD=$'\033[1m'
  readonly NOS_RESET=$'\033[0m'
else
  readonly NOS_ACCENT=''
  readonly NOS_OK=''
  readonly NOS_ERROR=''
  readonly NOS_BOLD=''
  readonly NOS_RESET=''
fi

nos_stage() {
  printf '%s%s[>] %s%s\n\n' "$NOS_BOLD" "$NOS_ACCENT" "$1" "$NOS_RESET"
}

nos_done() {
  printf '\n%s[✓] Done%s\n' "$NOS_OK" "$NOS_RESET"
}

nos_fail() {
  printf '\n%s[✗] %s%s\n' "$NOS_ERROR" "${1:-Failed}" "$NOS_RESET" >&2
}

nos_retry_prompt() {
  printf '\n%s[?] Retry? [Y/n]%s ' "$NOS_ERROR" "$NOS_RESET"
}

nos_repeat_prompt() {
  printf '\n%s[?] Repeat? [r/N]%s ' "$NOS_ACCENT" "$NOS_RESET"
}

nos_run() {
  local nix_config="${NIX_CONFIG:-}"

  if [[ -n "$nix_config" ]]; then
    nix_config+=$'\n'
  fi
  nix_config+='warn-dirty = false'

  NIX_CONFIG="$nix_config" "$@"
}

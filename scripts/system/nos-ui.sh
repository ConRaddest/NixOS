#!/usr/bin/env bash
# Shared terminal output helpers for nos-* scripts.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly NOS_ACCENT=$'\033[95m'
  readonly NOS_OK=$'\033[92m'
  readonly NOS_ERROR=$'\033[91m'
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
  printf '\n%s[✓] done%s\n' "$NOS_OK" "$NOS_RESET"
}

nos_fail() {
  printf '\n%s[✗] %s%s\n' "$NOS_ERROR" "${1:-failed}" "$NOS_RESET" >&2
}

nos_retry_prompt() {
  printf '\n%s[?] retry? [Y/n]%s ' "$NOS_ERROR" "$NOS_RESET"
}

nos_repeat_prompt() {
  printf '\n%s[?] go again? [y/N]%s ' "$NOS_ACCENT" "$NOS_RESET"
}

nos_run() {
  local nix_config="${NIX_CONFIG:-}"

  if [[ -n "$nix_config" ]]; then
    nix_config+=$'\n'
  fi
  nix_config+='warn-dirty = false'

  NIX_CONFIG="$nix_config" "$@"
}

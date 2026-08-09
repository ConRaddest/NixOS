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
  # Leading blank line separates headings from prior command output and also
  # gives every script a consistent top margin before its first heading.
  printf '\n%s%s[>] %s%s\n\n' "$NOS_BOLD" "$NOS_ACCENT" "$1" "$NOS_RESET"
}

nos_done() {
  printf '\n%s[✓] done%s\n' "$NOS_OK" "$NOS_RESET"
}

nos_fail() {
  printf '\n%s[✗] %s%s\n' "$NOS_ERROR" "${1:-failed}" "$NOS_RESET" >&2
}

nos_retry_prompt() {
  printf '\n%sretry? [Y/n]%s ' "$NOS_ERROR" "$NOS_RESET"
}

nos_repeat_prompt() {
  printf '\n%sgo again? [y/N]%s ' "$NOS_ACCENT" "$NOS_RESET"
}

nos_load_host_name() {
  [[ -n "${NOS_DIR:-}" ]] || return 0
  local env_file="$NOS_DIR/.env"
  local value

  [[ -f "$env_file" ]] || return 0
  value=$(sed -nE 's/^[[:space:]]*(export[[:space:]]+)?HOST_NAME[[:space:]]*=[[:space:]]*([^#[:space:]]+).*$/\2/p' "$env_file" | tail -n 1)
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  HOST_NAME="$value"
}

nos_host_name() {
  nos_load_host_name

  if [[ -z "${HOST_NAME:-}" ]]; then
    nos_fail "HOST_NAME missing; set export HOST_NAME=<host> in $NOS_DIR/.env"
    return 1
  fi

  if [[ ! "$HOST_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
    nos_fail "invalid HOST_NAME: $HOST_NAME"
    return 1
  fi

  printf '%s\n' "$HOST_NAME"
}

nos_run() {
  local nix_config="${NIX_CONFIG:-}"

  if [[ -n "$nix_config" ]]; then
    nix_config+=$'\n'
  fi
  nix_config+='warn-dirty = false'

  NIX_CONFIG="$nix_config" "$@"
}


#!/usr/bin/env bash
# Shared terminal output helpers for nos-* scripts.

# ╭──────────────────────────────────────────────────────────╮
# │ Presentation                                             │
# ╰──────────────────────────────────────────────────────────╯

nos_wordmark() {
  local wordmark="${NOS_DIR:-$HOME/NixOS}/assets/wordmark.txt"
  local accent=''
  local reset=''
  local color="${NOS_ACCENT_COLOR:-bb9af7}"
  local columns
  local max_width=0
  local padding=0
  local line
  local -a lines

  [[ "${NOS_WORDMARK_SHOWN:-}" != 1 ]] || return 0

  if [[ ! -r "$wordmark" ]]; then
    printf 'Wordmark is missing: %s\n' "$wordmark" >&2
    return 1
  fi

  color="${color#\#}"
  if [[ -z "${NO_COLOR:-}" && "$color" =~ ^[[:xdigit:]]{6}$ ]]; then
    printf -v accent '\033[38;2;%d;%d;%dm' \
      "$((16#${color:0:2}))" \
      "$((16#${color:2:2}))" \
      "$((16#${color:4:2}))"
    reset=$'\033[0m'
  fi

  mapfile -t lines < "$wordmark"
  for line in "${lines[@]}"; do
    (( ${#line} > max_width )) && max_width=${#line}
  done

  columns=$(tput cols 2>/dev/null || printf '%s' "${COLUMNS:-80}")
  (( columns > max_width )) && padding=$(( (columns - max_width) / 2 ))

  printf '%s' "$accent"
  for line in "${lines[@]}"; do
    if [[ -n "$line" ]]; then
      printf '%*s%s\n' "$padding" '' "$line"
    else
      printf '\n'
    fi
  done
  printf '%s\n' "$reset"
  export NOS_WORDMARK_SHOWN=1
}

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

# ╭──────────────────────────────────────────────────────────╮
# │ Operation terminals                                      │
# ╰──────────────────────────────────────────────────────────╯

nos_operation_terminal() {
  local operation="$1"
  local title="$2"
  shift 2

  [[ "${NOS_OPERATION_TERMINAL:-}" != "$operation" ]] || return 0

  NOS_OPERATION_TERMINAL="$operation" exec uwsm app -- kitty \
    --hold \
    --class "nos-$operation" \
    --title "$title" \
    -e "$0" "$@"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Host Selection                                           │
# ╰──────────────────────────────────────────────────────────╯

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
    printf 'HOST_NAME is missing. Add export HOST_NAME=<host> to %s/.env.\n' "$NOS_DIR" >&2
    return 1
  fi

  if [[ ! "$HOST_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
    printf 'Invalid HOST_NAME: %s\n' "$HOST_NAME" >&2
    return 1
  fi

  printf '%s\n' "$HOST_NAME"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Command Execution                                        │
# ╰──────────────────────────────────────────────────────────╯

nos_run() {
  local nix_config="${NIX_CONFIG:-}"

  if [[ -n "$nix_config" ]]; then
    nix_config+=$'\n'
  fi
  nix_config+='warn-dirty = false'

  NIX_CONFIG="$nix_config" "$@"
}

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

  printf '%s' "$accent"
  cat "$wordmark"
  printf '%s\n\n' "$reset"
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
# │ Desktop notifications and logs                           │
# ╰──────────────────────────────────────────────────────────╯

nos_begin() {
  local operation="$1"
  local operation_pid="$$"
  local title="NixOS ${operation^}"

  NOS_LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/nos-${operation}-XXXXXX.log")
  export NOS_LOG_FILE

  (
    local action
    action=$(notify-send \
      --app-name="NixOS" \
      --icon="$NOS_ICON" \
      --expire-time=15000 \
      --action="progress=Open in terminal" \
      "$title Started" \
      "Operation running in background.")

    if [[ "$action" == "progress" ]]; then
      uwsm app -- kitty \
        --hold \
        --class nos-progress \
        --title "$title Progress" \
        -e tail --pid="$operation_pid" -n +1 -f "$NOS_LOG_FILE" \
        >/dev/null 2>&1
    fi
  ) >/dev/null 2>&1 &
}

nos_capture() {
  "$@" 2>&1 | tee "$NOS_LOG_FILE"
  return "${PIPESTATUS[0]}"
}

nos_finish() {
  local status="$1"
  local title="$2"
  local message="$3"
  local urgency="normal"

  if [[ "$status" == "success" ]]; then
    wl-copy --type text/plain < "$NOS_LOG_FILE"
    message+=" Output copied to clipboard."
  else
    urgency="critical"
  fi

  (
    local action
    action=$(notify-send \
      --app-name="NixOS" \
      --icon="$NOS_ICON" \
      --urgency="$urgency" \
      --expire-time=15000 \
      --action="open=Open log" \
      "$title" \
      "$message Log: $NOS_LOG_FILE")

    if [[ "$action" == "open" ]]; then
      xdg-open "$NOS_LOG_FILE" >/dev/null 2>&1
    fi
  ) >/dev/null 2>&1 &
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

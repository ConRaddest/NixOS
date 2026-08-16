#!/usr/bin/env bash
# Shared terminal output helpers for nos-* scripts.

# ╭──────────────────────────────────────────────────────────╮
# │ Presentation                                             │
# ╰──────────────────────────────────────────────────────────╯

nos_wordmark() {
  local logo="${NOS_DIR:-$HOME/NixOS}/assets/logo.txt"
  local accent=''
  local reset=''
  local color="${NOS_ACCENT_COLOR:-bb9af7}"
  local subtitle="${1:-Declarative by Design}"
  local spaced_subtitle=''
  local columns
  local max_width=0
  local line
  local i
  local -a lines

  [[ "${NOS_WORDMARK_SHOWN:-}" != 1 ]] || return 0

  if [[ ! -r "$logo" ]]; then
    printf 'Wordmark is missing: %s\n' "$logo" >&2
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

  mapfile -t lines < "$logo"
  for line in "${lines[@]}"; do
    (( ${#line} > max_width )) && max_width=${#line}
  done
  columns=$(tput cols 2>/dev/null || printf '%s' "${COLUMNS:-80}")

  subtitle=${subtitle^^}
  for (( i = 0; i < ${#subtitle}; i++ )); do
    [[ -n "$spaced_subtitle" ]] && spaced_subtitle+=' '
    spaced_subtitle+="${subtitle:i:1}"
  done

  printf '%s' "$accent"
  if (( columns >= max_width )); then
    for line in "${lines[@]}"; do
      printf '%s\n' "$line"
    done
    printf '\n'
  fi

  if (( columns >= ${#spaced_subtitle} )); then
    printf '%s\n' "$spaced_subtitle"
  else
    printf '%s\n' "$subtitle"
  fi
  printf '%s\n' "$reset"
  export NOS_WORDMARK_SHOWN=1
}

# ╭──────────────────────────────────────────────────────────╮
# │ Operation terminals                                      │
# ╰──────────────────────────────────────────────────────────╯

nos_operation_terminal() {
  local operation="$1"
  local title="$2"
  shift 2

  # Reuse an existing Kitty terminal for nested operations such as
  # nos-install -> nos-refresh, then return to the calling interface.
  if [[ -n "${NOS_OPERATION_TERMINAL:-}" || -n "${KITTY_WINDOW_ID:-}" ]]; then
    return 0
  fi

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

# ╭──────────────────────────────────────────────────────────╮
# │ Transaction helpers                                      │
# ╰──────────────────────────────────────────────────────────╯

nos_changed_nix_files() {
  git -C "$NOS_DIR" diff --name-only --diff-filter=ACMR -z HEAD -- '*.nix'
}

nos_require_tracked_nix_files() {
  local -a files=()

  mapfile -d '' -t files < <(
    git -C "$NOS_DIR" ls-files --others --exclude-standard -z -- '*.nix'
  )
  ((${#files[@]} == 0)) && return 0

  printf 'Untracked Nix files are excluded from flake evaluation:\n' >&2
  printf '  %s\n' "${files[@]}" >&2
  printf 'Track them first with: git add -N -- <file>\n' >&2
  return 1
}

nos_transaction_begin() {
  local file

  NOS_TRANSACTION_DIR=$(mktemp -d)
  NOS_TRANSACTION_FILES=()
  for file in "$@"; do
    [[ -f "$NOS_DIR/$file" ]] || continue
    NOS_TRANSACTION_FILES+=("$file")
    (cd "$NOS_DIR" && cp --parents -- "$file" "$NOS_TRANSACTION_DIR")
  done
  export NOS_TRANSACTION_DIR
}

nos_transaction_restore() {
  local file

  [[ -n "${NOS_TRANSACTION_DIR:-}" && -d "$NOS_TRANSACTION_DIR" ]] || return 0
  for file in "${NOS_TRANSACTION_FILES[@]:-}"; do
    [[ -f "$NOS_TRANSACTION_DIR/$file" ]] && cp -- "$NOS_TRANSACTION_DIR/$file" "$NOS_DIR/$file"
  done
  rm -rf -- "$NOS_TRANSACTION_DIR"
  NOS_TRANSACTION_DIR=''
}

nos_transaction_finish() {
  [[ -z "${NOS_TRANSACTION_DIR:-}" ]] || rm -rf -- "$NOS_TRANSACTION_DIR"
  NOS_TRANSACTION_DIR=''
}

nos_format_changed_nix() {
  local -a files=()

  mapfile -d '' -t files < <(nos_changed_nix_files)
  ((${#files[@]} == 0)) || (cd "$NOS_DIR" && nixfmt "${files[@]}")
}

#!/usr/bin/env bash
set -euo pipefail

viewer_class="windows-vm"
config_file="${HOME}/VMs/windows/config.env"
log_file="${HOME}/.local/state/windows-vm.log"

mode="foreground"
if [[ "${1:-}" == "--background" ]]; then
  mode="background"
  shift
fi

if [[ -f "$config_file" ]]; then
  # shellcheck disable=SC1090
  source "$config_file"
fi

user="${1:-${USERNAME:-}}"
pass="${PASSWORD:-}"
args_file="$(mktemp --tmpdir windows-vm-rdp.XXXXXX)"
chmod 600 "$args_file"

cleanup() {
  rm -f "$args_file"
}

write_rdp_args() {
  {
    printf '%s\n' "/v:127.0.0.1:3389"
    printf '%s\n' "/u:$user"
    [[ -n "$pass" ]] && printf '%s\n' "/p:$pass"
    printf '%s\n' "/dynamic-resolution"
    printf '%s\n' "/clipboard"
    printf '%s\n' "/cert:ignore"
    printf '%s\n' "/network:auto"
    printf '%s\n' "/scale:100"
    printf '%s\n' "+rfx"
    printf '%s\n' "/gfx:progressive"
    printf '%s\n' "/wm-class:$viewer_class"
    printf '%s\n' "/t:Windows"
  } > "$args_file"
}

rdp_command() {
  if command -v xfreerdp3 >/dev/null 2>&1; then
    printf '%s\n' "xfreerdp3"
  else
    printf '%s\n' "xfreerdp"
  fi
}

write_rdp_args
rdp_bin="$(rdp_command)"

case "$mode" in
  foreground)
    trap cleanup EXIT
    exec "$rdp_bin" /args-from:file:"$args_file"
    ;;
  background)
    mkdir -p "$(dirname "$log_file")"
    : > "$log_file"
    "$rdp_bin" /args-from:file:"$args_file" >>"$log_file" 2>&1 &
    (sleep 5; cleanup) >/dev/null 2>&1 &
    ;;
  *)
    echo "usage: windows-vm-rdp [--background] [username]" >&2
    cleanup
    exit 2
    ;;
esac

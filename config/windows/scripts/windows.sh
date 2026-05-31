#!/usr/bin/env bash
set -euo pipefail

container="Windows"
legacy_container="WinApps"
viewer_class="windows-vm"
credential_class="windows-credentials"
base_dir="${HOME}/VMs/windows"
config_file="${base_dir}/config.env"

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$container"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$container"
}

viewer_address() {
  hyprctl clients -j 2>/dev/null \
    | jq -r --arg klass "$viewer_class" '
      .[]
      | select(.class == $klass or .initialClass == $klass)
      | .address
    ' \
    | head -n 1
}

focus_viewer() {
  local address
  address="$(viewer_address)"
  if [[ -n "$address" && "$address" != "null" ]]; then
    hyprctl dispatch focuswindow "address:$address" >/dev/null
    return 0
  fi
  return 1
}

wait_for_rdp() {
  for _ in $(seq 1 90); do
    if timeout 1 bash -c '</dev/tcp/127.0.0.1/3389' >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

prompt_credentials() {
  mkdir -p "$base_dir"
  exec kitty \
    --class "$credential_class" \
    --title windows-credentials \
    -e bash -lc '
      set -euo pipefail
      config_file="$HOME/VMs/windows/config.env"
      read -rp "Windows username []: " user
      user="${user:-}"
      read -rsp "Windows password: " pass
      echo
      mkdir -p "$(dirname "$config_file")"
      {
        printf "USERNAME=%q\n" "$user"
        printf "PASSWORD=%q\n" "$pass"
      } > "$config_file"
      chmod 600 "$config_file"
      exec windows-vm
    '
}

open_viewer() {
  if focus_viewer; then
    return 0
  fi

  if [[ ! -f "$config_file" ]]; then
    prompt_credentials
  fi

  windows-vm-rdp --background
}

if ! container_exists && docker ps -a --format '{{.Names}}' | grep -qx "$legacy_container"; then
  docker rename "$legacy_container" "$container"
fi

if ! container_exists; then
  echo "Windows VM is not installed yet."
  read -rp "Run windows-install now? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) exec windows-install ;;
    *) echo "Cancelled. Run windows-install when you are ready."; exit 1 ;;
  esac
fi

if container_running; then
  if wait_for_rdp; then
    open_viewer
  else
    echo "RDP is not ready." >&2
    exit 1
  fi
  exit 0
fi

# Container is stopped — start it in a visible terminal so the user can see progress.
exec kitty \
  --class windows-vm-start \
  --title windows-vm-start \
  -e windows-vm-start

set -euo pipefail

container="Windows"
legacy_container="WinApps"
viewer_class="windows-vm"
credential_class="windows-credentials"
base_dir="${HOME}/VMs/windows"
config_file="${base_dir}/config.env"
compose_file="${HOME}/.config/windows/docker-compose.yaml"
log_file="${HOME}/.local/state/windows-vm.log"

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
      read -rp "Windows username [cdt]: " user
      user="${user:-cdt}"
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

  # shellcheck disable=SC1090
  source "$config_file"

  local user="${USERNAME:-cdt}"
  local pass="${PASSWORD:-}"
  local args_file
  args_file="$(mktemp --tmpdir windows-vm-rdp.XXXXXX)"
  chmod 600 "$args_file"
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

  mkdir -p "$(dirname "$log_file")"
  : > "$log_file"
  if command -v xfreerdp3 >/dev/null 2>&1; then
    xfreerdp3 /args-from:file:"$args_file" >>"$log_file" 2>&1 &
  else
    xfreerdp /args-from:file:"$args_file" >>"$log_file" 2>&1 &
  fi
  (sleep 5; rm -f "$args_file") >/dev/null 2>&1 &
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

if ! container_running; then
  if [[ -f "$compose_file" ]]; then
    docker compose --file "$compose_file" up -d >/dev/null
  else
    docker start "$container" >/dev/null
  fi
  echo "Windows VM started."
else
  echo "Windows VM is already running."
fi

if wait_for_rdp; then
  open_viewer
else
  echo "RDP is not ready yet. Installer/web viewer may still be available at http://localhost:8006"
  exit 1
fi

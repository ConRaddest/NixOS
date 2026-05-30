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
  --class nixos-refresh \
  --title nixos-refresh \
  -e bash -lc '
    set -euo pipefail
    trap '\''echo; read -rp "Press Enter to close..."'\'' ERR

    echo "Starting Windows VM..."
    docker rm -f "Windows" >/dev/null 2>&1 || true
    docker compose --file "$HOME/.config/windows/docker-compose.yaml" up -d >/dev/null

    echo "Waiting for Windows to be ready..."
    ready=false
    for i in $(seq 1 300); do
      if timeout 1 bash -c "</dev/tcp/127.0.0.1/3389" 2>/dev/null; then
        ready=true
        break
      fi
      printf "\r  %3ds elapsed..." "$i"
      sleep 1
    done
    printf "\r\033[K"

    if [[ "$ready" != "true" ]]; then
      echo "Timed out. Windows may still be booting — check http://localhost:8006"
      read -rp "Press Enter to close..."
      exit 1
    fi

    echo "Windows is ready — connecting..."
    connected=false
    for attempt in $(seq 1 30); do
      setsid windows-vm-rdp >/dev/null 2>&1 &
      rdp_pid=$!
      sleep 5
      if kill -0 "$rdp_pid" 2>/dev/null; then
        connected=true
        break
      fi
      wait "$rdp_pid" 2>/dev/null || true
      printf "\rWaiting for RDP service..."
      sleep 3
    done
    printf "\r\033[K"

    if [[ "$connected" != "true" ]]; then
      echo "Failed to connect — check http://localhost:8006"
      read -rp "Press Enter to close..."
      exit 1
    fi

    echo "Connected successfully."
    read -rp "Press Enter to close..."
  '

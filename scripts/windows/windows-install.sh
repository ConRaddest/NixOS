#!/usr/bin/env bash
set -euo pipefail

NOS_DIR="$HOME/NixOS"
export NOS_DIR

if [[ "${WINDOWS_INSTALL_IN_TERMINAL:-0}" != "1" ]]; then
  exec kitty \
    --class windows-install \
    --title windows-install \
    -e bash -lc "WINDOWS_INSTALL_IN_TERMINAL=1 windows-install"
fi

container="Windows"
base_dir="${HOME}/VMs/windows"
storage="${base_dir}/storage"
shared="${HOME}/Windows"
env_file="${NOS_DIR}/.env"
compose_file="${HOME}/.config/windows/docker-compose.yaml"

set_env_var() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"

  touch "$env_file"
  chmod 600 "$env_file"
  grep -Ev "^(export[[:space:]]+)?${key}=" "$env_file" > "$tmp" || true
  printf 'export %s=%q\n' "$key" "$value" >> "$tmp"
  cat "$tmp" > "$env_file"
  rm -f "$tmp"
}

if ! [[ -e /dev/kvm ]]; then
  echo "error: /dev/kvm is missing. Reboot or check that virtualization is enabled." >&2
  exit 1
fi

if ! [[ -f "$compose_file" ]]; then
  echo "error: missing compose file: $compose_file" >&2
  echo "Run: home-manager switch --flake $NOS_DIR#" >&2
  exit 1
fi

echo "Windows VM install"
echo

echo "Modify $NOS_DIR/config/windows/docker-compose.yaml to change VM settings."

read -rp "Windows username [Docker]: " username
username="${username:-Docker}"
read -rsp "Windows password: " password
echo
if [[ -z "$password" ]]; then
  echo "error: password cannot be empty." >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
  echo "A Windows VM container already exists."
  read -rp "Remove and recreate it? This keeps files in $storage. [y/N] " recreate
  case "$recreate" in
    y|Y|yes|YES)
      docker rm -f "$container" >/dev/null
      ;;
    *)
      echo "Cancelled."
      exit 1
      ;;
  esac
fi

mkdir -p "$storage" "$shared"
set_env_var WINDOWS_USERNAME "$username"
set_env_var WINDOWS_PASSWORD "$password"
export WINDOWS_USERNAME="$username"
export WINDOWS_PASSWORD="$password"

echo
echo "Pulling latest dockurr/windows image..."
docker pull dockurr/windows:latest

echo
echo "Starting Windows installer from compose file..."
docker compose --file "$compose_file" up -d

echo
echo "Windows installer is starting."
echo "Installer viewer: http://localhost:8006"
echo "After Windows finishes installing, Apps → Windows opens a the vm."
echo
read -rp "Press Enter to close..."

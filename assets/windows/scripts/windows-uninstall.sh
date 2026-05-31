#!/usr/bin/env bash
set -euo pipefail

if [[ "${WINDOWS_UNINSTALL_IN_TERMINAL:-0}" != "1" ]]; then
  exec kitty \
    --class windows-uninstall \
    --title windows-uninstall \
    -e bash -lc "WINDOWS_UNINSTALL_IN_TERMINAL=1 windows-uninstall; echo; read -rp 'Press Enter to close...'"
fi

container="Windows"
base_dir="${HOME}/VMs/windows"
shared="${HOME}/Windows"
compose_file="${HOME}/.config/windows/docker-compose.yaml"

echo "Windows VM uninstall"
echo

echo "This will permanently remove:"
echo "  - Docker container and image"
echo "  - VM disk and config: $base_dir"
echo "  - Shared folder:      $shared"
echo
read -rp "Are you sure? This cannot be undone. [y/N] " confirm
case "$confirm" in
  y|Y|yes|YES) ;;
  *) echo "Cancelled."; exit 1 ;;
esac

if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
  echo "Stopping and removing container..."
  docker rm -f "$container" >/dev/null
fi

if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "dockurr/windows"; then
  echo "Removing Docker image..."
  docker rmi dockurr/windows:latest >/dev/null 2>&1 || true
fi

if [[ -d "$base_dir" ]]; then
  echo "Removing VM disk and config..."
  rm -rf "$base_dir"
fi

if [[ -d "$shared" ]]; then
  echo "Removing shared folder..."
  rm -rf "$shared"
fi

echo
echo "Windows VM removed."

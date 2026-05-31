#!/usr/bin/env bash
set -euo pipefail
trap 'echo; read -rp "Press Enter to close..."' ERR

container="Windows"
compose_file="${HOME}/.config/windows/docker-compose.yaml"

printf '\033[1;36mStarting Windows VM...\033[0m\n\n'
echo "Starting Windows container..."
docker rm -f "$container" >/dev/null 2>&1 || true
docker compose --progress quiet --file "$compose_file" up -d >/dev/null

echo "Waiting for Windows to be ready..."
ready=false
for i in $(seq 1 300); do
  if timeout 1 bash -c '</dev/tcp/127.0.0.1/3389' 2>/dev/null; then
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

connected=false
for _ in $(seq 1 30); do
  setsid windows-vm-rdp >/dev/null 2>&1 &
  rdp_pid=$!
  sleep 5
  if kill -0 "$rdp_pid" 2>/dev/null; then
    connected=true
    break
  fi
  wait "$rdp_pid" 2>/dev/null || true
  echo "Windows is ready — attempting to start session..."
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

set -euo pipefail

: "${OS_CONFIG_DIR:?OS_CONFIG_DIR is not set}"

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
config_file="${base_dir}/config.env"
compose_file="${HOME}/.config/windows/docker-compose.yaml"

if ! [[ -e /dev/kvm ]]; then
  echo "error: /dev/kvm is missing. Reboot or check that virtualization is enabled." >&2
  exit 1
fi

if ! [[ -f "$compose_file" ]]; then
  echo "error: missing compose file: $compose_file" >&2
  echo "Run: home-manager switch --flake $OS_CONFIG_DIR#cdt" >&2
  exit 1
fi

echo "Windows VM install"
echo

echo "Modify $OS_CONFIG_DIR/config/windows/docker-compose.yaml to change vm settings..."

username="$(grep -E '^      USERNAME:' "$compose_file" | sed -E 's/^ *USERNAME: *"?([^" ]+)"?.*/\1/' | tail -1)"
password="$(grep -E '^      PASSWORD:' "$compose_file" | sed -E 's/^ *PASSWORD: *"?([^" ]+)"?.*/\1/' | tail -1)"
username="${username:-cdt}"
password="${password:-admin}"

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
cat > "$config_file" <<EOF
USERNAME=$username
PASSWORD=$password
EOF
chmod 600 "$config_file"

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

#!/usr/bin/env bash
# Create new host configuration without changing existing hosts.
# Run from inside this repository. Pass --root /mnt from a NixOS installer.
set -euo pipefail

usage() {
  printf 'usage: %s [--root PATH]\n' "$(basename "$0")" >&2
  exit 2
}

root_args=()
if [[ "${1:-}" == "--root" ]]; then
  [[ -n "${2:-}" ]] || usage
  root_args=(--root "$2")
  shift 2
fi
[[ $# -eq 0 ]] || usage

repo_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "error: run script from inside Git repository." >&2
  exit 1
}

template_dir="$repo_dir/hosts/_template"
hosts_dir="$repo_dir/hosts"
[[ -f "$template_dir/host.nix" ]] || {
  echo "error: missing template: $template_dir/host.nix" >&2
  exit 1
}
[[ -f "$template_dir/hardware.nix" ]] || {
  echo "error: missing template: $template_dir/hardware.nix" >&2
  exit 1
}

if ! command -v nixos-generate-config >/dev/null 2>&1; then
  echo "error: nixos-generate-config is unavailable." >&2
  echo "run this from NixOS or a NixOS installer." >&2
  exit 1
fi

if ! sudo -v; then
  echo "error: sudo authentication failed." >&2
  exit 1
fi

ask() {
  local prompt="$1"
  local default="$2"
  local answer
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " answer
  else
    read -r -p "$prompt: " answer
  fi
  printf '%s' "${answer:-$default}"
}

ask_yes_no() {
  local prompt="$1"
  local default="$2"
  local answer
  local hint
  if [[ "${default,,}" == y* ]]; then
    hint='[Y/n]'
  else
    hint='[y/N]'
  fi
  while true; do
    read -r -p "$prompt? $hint: " answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "answer yes or no." >&2 ;;
    esac
  done
}

ask_choice() {
  local prompt="$1"
  local default="$2"
  shift 2
  local choices=("$@")
  local answer choice index

  printf '%s\n' "$prompt" >&2
  for index in "${!choices[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${choices[$index]}" >&2
  done

  while true; do
    read -r -p "choice [${default}]: " answer
    answer="${answer:-$default}"
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#choices[@]} )); then
      choice="${choices[$((answer - 1))]}"
      printf '%s' "$choice"
      return
    fi
    echo "choose a listed number." >&2
  done
}

validate_name() {
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]
}

sed_replacement() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

host_default=$(hostname -s 2>/dev/null || printf 'new-host')
host_name=$(ask "hostname" "$host_default")
validate_name "$host_name" || {
  echo "error: hostname must contain only letters, numbers, and hyphens." >&2
  exit 1
}
[[ "$host_name" != _* ]] || {
  echo "error: hostname cannot start with underscore." >&2
  exit 1
}

host_dir="$hosts_dir/$host_name"
[[ ! -e "$host_dir" ]] || {
  echo "error: host already exists: $host_dir" >&2
  echo "existing host configuration will not be replaced." >&2
  exit 1
}

username_default="${SUDO_USER:-${USER:-cdt}}"
username=$(ask "username" "$username_default")
validate_name "$username" || {
  echo "error: username must contain only letters, numbers, and hyphens." >&2
  exit 1
}

full_name=$(ask "full name" "Connor du Toit")
home_directory="/home/$username"
flake_directory=$(ask "config path" "$repo_dir")

system_arch=$(uname -m)
case "$system_arch" in
  x86_64) system="x86_64-linux" ;;
  *)
    echo "error: this flake currently supports x86_64-linux only; detected $system_arch." >&2
    exit 1
    ;;
esac

printf '\nhardware options:\n\n'
gpu=$(ask_choice "gpu" 2 nvidia amd intel)

if ask_yes_no "battery" "$(if compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then echo y; else echo n; fi)"; then
  battery=true
else
  battery=false
fi

if ask_yes_no "bluetooth" y; then
  bluetooth=true
else
  bluetooth=false
fi

if ask_yes_no "audio / pipewire" y; then
  audio=true
else
  audio=false
fi

if ask_yes_no "docker" y; then
  docker=true
else
  docker=false
fi

windows=false
if [[ "$docker" == true ]]; then
  if ask_yes_no "windows vm" n; then
    windows=true
  fi
fi

if ask_yes_no "1password / ssh agent" y; then
  onepassword=true
else
  onepassword=false
fi

if ask_yes_no "printing" y; then
  printing=true
else
  printing=false
fi

if ask_yes_no "trackpad" n; then
  trackpad=true
  trackpad_name=$(ask "trackpad device name" "")
else
  trackpad=false
  trackpad_name=""
fi

printf '\nCreating host: %s\n' "$host_name"
printf 'Repository: %s\n' "$repo_dir"
printf 'Architecture: %s\n\n' "$system"

cp -R "$template_dir" "$host_dir"
host_file="$host_dir/host.nix"
hardware_file="$host_dir/hardware.nix"

escaped_user=$(sed_replacement "$username")
escaped_full_name=$(sed_replacement "$full_name")
escaped_home=$(sed_replacement "$home_directory")
escaped_flake=$(sed_replacement "$flake_directory")
escaped_trackpad=$(sed_replacement "$trackpad_name")

sed -i \
  -e "s|fullName = \"CHANGE_ME\";|fullName = \"$escaped_full_name\";|" \
  -e "s|CHANGE_ME|$escaped_user|g" \
  -e "s|homeDirectory = \"/home/$escaped_user\";|homeDirectory = \"$escaped_home\";|" \
  -e "s|flakeDirectory = \"/home/$escaped_user/NixOS\";|flakeDirectory = \"$escaped_flake\";|" \
  -e "s|trackpad = false;|trackpad = $trackpad;|" \
  "$host_file"

if [[ -n "$trackpad_name" ]]; then
  sed -i "s|trackpadName = null;|trackpadName = \"$escaped_trackpad\";|" "$host_file"
fi

inject_module() {
  local marker="$1"
  local module="$2"
  sed -i "s|        # $marker|        $module|" "$host_file"
}

inject_module GPU_MODULE "self.nixosModules.$gpu"
[[ "$battery" == true ]] && {
  inject_module BATTERY_SYSTEM_MODULE "self.nixosModules.battery"
  inject_module BATTERY_HOME_MODULE "self.lib.homeModules.battery"
}
[[ "$bluetooth" == true ]] && {
  inject_module BLUETOOTH_SYSTEM_MODULE "self.nixosModules.bluetooth"
  inject_module BLUETOOTH_HOME_MODULE "self.lib.homeModules.bluetooth"
}
[[ "$audio" == true ]] && {
  inject_module AUDIO_SYSTEM_MODULE "self.nixosModules.audio"
  inject_module AUDIO_HOME_MODULE "self.lib.homeModules.audio"
}
[[ "$docker" == true ]] && {
  inject_module DOCKER_SYSTEM_MODULE "self.nixosModules.docker"
  inject_module DOCKER_HOME_MODULE "self.lib.homeModules.lazydocker"
}
[[ "$windows" == true ]] &&
  inject_module WINDOWS_HOME_MODULE "self.lib.homeModules.windows"
[[ "$onepassword" == true ]] && {
  inject_module ONEPASSWORD_SYSTEM_MODULE "self.nixosModules.onepassword"
  inject_module ONEPASSWORD_HOME_MODULE "self.lib.homeModules.ssh"
}
[[ "$printing" == true ]] &&
  inject_module PRINTING_SYSTEM_MODULE "self.nixosModules.printing"
sed -i -E '/^[[:space:]]*#[[:space:]]+[A-Z_]+_MODULE$/d' "$host_file"

hardware_tmp=$(mktemp)
trap 'rm -f "$hardware_tmp"' EXIT

printf '\nGenerating hardware configuration...\n'
sudo nixos-generate-config "${root_args[@]}" --show-hardware-config > "$hardware_tmp"

if ! grep -qE '^\{[[:space:]]*$' "$hardware_tmp" || ! tail -n 1 "$hardware_tmp" | grep -qE '^\}[[:space:]]*$'; then
  echo "error: unexpected nixos-generate-config output." >&2
  rm -rf "$host_dir"
  exit 1
fi

{
  cat <<EOF
# Generated by nos-new-host.sh from nixos-generate-config.
# Re-run installer for a different machine; do not replace another host.
{ ... }:

let
  hostName = builtins.baseNameOf (toString ./.);
in
{
  flake.nixosModules."${host_name}Hardware" =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
EOF
  awk '
    BEGIN { body = 0; count = 0 }
    /^\{[[:space:]]*$/ { body = 1; next }
    body { lines[++count] = $0 }
    END {
      if (count > 0 && lines[count] ~ /^[[:space:]]*}[[:space:]]*$/) count--
      for (i = 1; i <= count; i++) print lines[i]
    }
  ' "$hardware_tmp"
  cat <<EOF
    };
}
EOF
} > "$hardware_file"
printf '\nCreated:\n  %s\n  %s\n' "$host_file" "$hardware_file"
printf '\nNext steps:\n'
printf '  sudo nixos-rebuild switch --flake %s#%s\n' "$flake_directory" "$host_name"
printf '  home-manager switch --flake %s#%s@%s\n' "$flake_directory" "$username" "$host_name"
printf '  add `export HOST_NAME=%s` to %s/.env on target machine\n' "$host_name" "$flake_directory"

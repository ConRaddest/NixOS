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

nix_string_replacement() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$\{/\\\$\{}"
  sed_replacement "$value"
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

full_name=$(ask "full name" "$username")
git_email=$(ask "git email" "$username@$(hostname -s)")
time_zone=$(ask "time zone" "UTC")
locale=$(ask "locale" "en_US.UTF-8")
keyboard_layout=$(ask "keyboard layout" "us")
state_version_default=$(nixos-version 2>/dev/null | cut -d. -f1,2)
state_version=$(ask "NixOS state version" "${state_version_default:-26.05}")
home_directory="/home/$username"
flake_directory=$(ask "config path on target" "/home/$username/NixOS")

command -v mkpasswd >/dev/null 2>&1 || {
  echo "error: mkpasswd is required to create initial login password hash." >&2
  echo "run: nix shell nixpkgs#mkpasswd" >&2
  exit 1
}
while true; do
  read -r -s -p "initial login password: " password
  printf '\n'
  read -r -s -p "confirm login password: " password_confirm
  printf '\n'
  [[ -n "$password" ]] || {
    echo "password cannot be empty." >&2
    continue
  }
  [[ "$password" == "$password_confirm" ]] && break
  echo "passwords do not match." >&2
done
initial_password_hash=$(printf '%s' "$password" | mkpasswd -m yescrypt -s)
unset password password_confirm

system_arch=$(uname -m)
case "$system_arch" in
  x86_64) system="x86_64-linux" ;;
  *)
    echo "error: this flake currently supports x86_64-linux only; detected $system_arch." >&2
    exit 1
    ;;
esac

printf '\nhardware options:\n\n'
if [[ -d /sys/firmware/efi ]]; then
  boot_default=1
else
  boot_default=2
fi
boot_mode=$(ask_choice "boot mode" "$boot_default" uefi bios)
if [[ "$boot_mode" == bios ]]; then
  boot_device=$(ask "GRUB install device" "/dev/sda")
else
  boot_device=""
fi

gpu=$(ask_choice "graphics" 1 none nvidia amd intel)
nvidia_open=false
nvidia_prime_value=null
if [[ "$gpu" == nvidia ]]; then
  if ask_yes_no "NVIDIA open kernel modules" n; then
    nvidia_open=true
  fi
  if ask_yes_no "hybrid PRIME graphics" n; then
    integrated_gpu=$(ask_choice "integrated gpu" 1 intel amd)
    integrated_bus_id=$(ask "integrated GPU bus ID" "PCI:0:2:0")
    nvidia_bus_id=$(ask "NVIDIA GPU bus ID" "PCI:1:0:0")
    [[ "$integrated_bus_id" =~ ^PCI:[0-9]+:[0-9]+:[0-9]+$ ]] || {
      echo "error: invalid integrated GPU bus ID." >&2
      exit 1
    }
    [[ "$nvidia_bus_id" =~ ^PCI:[0-9]+:[0-9]+:[0-9]+$ ]] || {
      echo "error: invalid NVIDIA GPU bus ID." >&2
      exit 1
    }
    nvidia_prime_value="{ integratedGpu = \"$integrated_gpu\"; integratedBusId = \"$integrated_bus_id\"; nvidiaBusId = \"$nvidia_bus_id\"; offload = true; }"
  fi
fi

if ask_yes_no "Steam / gaming support" y; then
  gaming=true
else
  gaming=false
fi

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

deep_sleep=false
thermald=false
if [[ "$battery" == true ]]; then
  if ask_yes_no "request deep suspend" n; then
    deep_sleep=true
  fi
  if grep -qi 'GenuineIntel' /proc/cpuinfo 2>/dev/null && ask_yes_no "Intel thermald" y; then
    thermald=true
  fi
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

escaped_user=$(nix_string_replacement "$username")
escaped_full_name=$(nix_string_replacement "$full_name")
escaped_git_email=$(nix_string_replacement "$git_email")
escaped_home=$(nix_string_replacement "$home_directory")
escaped_flake=$(nix_string_replacement "$flake_directory")
escaped_trackpad=$(nix_string_replacement "$trackpad_name")
escaped_password_hash=$(nix_string_replacement "$initial_password_hash")
escaped_time_zone=$(nix_string_replacement "$time_zone")
escaped_locale=$(nix_string_replacement "$locale")
escaped_keyboard=$(nix_string_replacement "$keyboard_layout")
escaped_state_version=$(nix_string_replacement "$state_version")
cpu_cores=$(nproc)

if [[ -n "$boot_device" ]]; then
  escaped_boot_device=$(sed_replacement "$boot_device")
  boot_device_value="\"$escaped_boot_device\""
else
  boot_device_value=null
fi

sed -i \
  -e "s|username = \"CHANGE_ME\";|username = \"$escaped_user\";|" \
  -e "s|fullName = \"CHANGE_ME\";|fullName = \"$escaped_full_name\";|" \
  -e "s|homeDirectory = \"/home/CHANGE_ME\";|homeDirectory = \"$escaped_home\";|" \
  -e "s|flakeDirectory = \"/home/CHANGE_ME/NixOS\";|flakeDirectory = \"$escaped_flake\";|" \
  -e "s|stateVersion = \"26.05\";|stateVersion = \"$escaped_state_version\";|" \
  -e "s|initialHashedPassword = null;|initialHashedPassword = \"$escaped_password_hash\";|" \
  -e "s|gaming = true;|gaming = $gaming;|" \
  -e "s|mode = \"uefi\";|mode = \"$boot_mode\";|" \
  -e "s|device = null;|device = $boot_device_value;|" \
  -e "s|deepSleep = false;|deepSleep = $deep_sleep;|" \
  -e "s|thermald = false;|thermald = $thermald;|" \
  -e "s|nvidiaOpen = false;|nvidiaOpen = $nvidia_open;|" \
  -e "s|nvidiaPrime = null;|nvidiaPrime = $nvidia_prime_value;|" \
  -e "s|name = \"CHANGE_ME\";|name = \"$escaped_full_name\";|" \
  -e "s|email = \"CHANGE_ME\";|email = \"$escaped_git_email\";|" \
  -e "s|timeZone = \"UTC\";|timeZone = \"$escaped_time_zone\";|g" \
  -e "s|locale = \"en_US.UTF-8\";|locale = \"$escaped_locale\";|" \
  -e "s|keyboardLayout = \"us\";|keyboardLayout = \"$escaped_keyboard\";|" \
  -e "s|gduMaxCores = 4;|gduMaxCores = $cpu_cores;|" \
  -e "s|cpuCores = 4;|cpuCores = $cpu_cores;|" \
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

[[ "$gpu" != none ]] &&
  inject_module GPU_MODULE "self.nixosModules.$gpu"
[[ "$nvidia_prime_value" != null ]] &&
  inject_module INTEGRATED_GPU_MODULE "self.nixosModules.$integrated_gpu"
[[ "$gaming" == true ]] &&
  inject_module GAMING_SYSTEM_MODULE "self.nixosModules.gaming"
[[ "$gaming" != true ]] && sed -i '/^steam$/d' "$host_dir/apps.txt"
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
      pkgs,
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
printf '  sudo nixos-rebuild switch --flake path:%s#%s\n' "$flake_directory" "$host_name"
printf '  system rebuild also activates Home Manager for %s\n' "$username"
printf '  add `export HOST_NAME=%s` to %s/.env on target machine\n' "$host_name" "$flake_directory"
printf '  customize monitors in %s/hosts/%s/host.nix when needed\n' "$flake_directory" "$host_name"

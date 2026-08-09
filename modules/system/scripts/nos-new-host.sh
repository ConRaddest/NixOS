#!/usr/bin/env bash
# Create new host configuration without changing existing hosts.
# Run from inside this repository. Pass --root /mnt from a NixOS installer.
set -euo pipefail

# ╭──────────────────────────────────────────────────────────╮
# │ Presentation                                             │
# ╰──────────────────────────────────────────────────────────╯

readonly NOS_HEADING_TOP='╭──────────────────────────────────────────────────────────╮'
readonly NOS_HEADING_BOTTOM='╰──────────────────────────────────────────────────────────╯'

print_heading() {
  printf '\n%s\n' "$NOS_HEADING_TOP"
  printf '│ %-56s │\n' "$1"
  printf '%s\n\n' "$NOS_HEADING_BOTTOM"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Arguments                                                │
# ╰──────────────────────────────────────────────────────────╯

usage() {
  printf 'Usage: %s [--root PATH]\n' "$(basename "$0")" >&2
  exit 2
}

root_args=()
if [[ "${1:-}" == "--root" ]]; then
  [[ -n "${2:-}" ]] || usage
  root_args=(--root "$2")
  shift 2
fi
[[ $# -eq 0 ]] || usage

# ╭──────────────────────────────────────────────────────────╮
# │ Requirements                                             │
# ╰──────────────────────────────────────────────────────────╯

repo_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: Run this command from inside the Git repository." >&2
  exit 1
}

template_dir="$repo_dir/hosts/_template"
hosts_dir="$repo_dir/hosts"
[[ -f "$template_dir/host.nix" ]] || {
  echo "Error: Host template is missing: $template_dir/host.nix" >&2
  exit 1
}
[[ -f "$template_dir/hardware.nix" ]] || {
  echo "Error: Hardware template is missing: $template_dir/hardware.nix" >&2
  exit 1
}

if ! command -v nixos-generate-config >/dev/null 2>&1; then
  echo "Error: nixos-generate-config is unavailable." >&2
  echo "Run this command from NixOS or a NixOS installer." >&2
  exit 1
fi

if ! sudo -v; then
  echo "Error: sudo authentication failed." >&2
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "Error: fzf is required for interactive selection lists." >&2
  echo "Install it temporarily with: nix shell nixpkgs#fzf" >&2
  exit 1
fi

# ╭──────────────────────────────────────────────────────────╮
# │ Prompt Helpers                                           │
# ╰──────────────────────────────────────────────────────────╯

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
      *) echo "Please answer yes or no." >&2 ;;
    esac
  done
}

choice_label() {
  case "$1" in
    uefi) printf 'UEFI' ;;
    bios) printf 'BIOS' ;;
    none) printf 'None' ;;
    nvidia) printf 'NVIDIA' ;;
    amd) printf 'AMD' ;;
    intel) printf 'Intel' ;;
    *) printf '%s' "$1" ;;
  esac
}

status_label() {
  if [[ "$1" == true ]]; then
    printf 'Enabled'
  else
    printf 'Disabled'
  fi
}

ask_choice() {
  local prompt="$1"
  local default_index="$2"
  shift 2
  local choices=("$@")
  local labels=()
  local choice selected index

  for choice in "${choices[@]}"; do
    labels+=("$(choice_label "$choice")")
  done

  selected=$(printf '%s\n' "${labels[@]}" | ask_list "$prompt" "${labels[$((default_index - 1))]}")
  for index in "${!labels[@]}"; do
    if [[ "${labels[$index]}" == "$selected" ]]; then
      printf '%s' "${choices[$index]}"
      return
    fi
  done

  echo "Error: Invalid selection returned by fzf." >&2
  exit 1
}

ask_list() {
  local prompt="$1"
  local default="$2"
  local selected
  local values

  values=$(cat)
  selected=$(
    {
      printf '%s\n' "$default"
      printf '%s\n' "$values"
    } \
      | awk 'NF && !seen[$0]++' \
      | fzf \
          --height=70% \
          --layout=reverse \
          --border \
          --prompt="$prompt: " \
          --header="Type to filter · Enter to select · Default: $default"
  ) || {
    echo "Selection cancelled." >&2
    exit 1
  }

  printf '%s' "$selected"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Selection Data                                           │
# ╰──────────────────────────────────────────────────────────╯

nixpkgs_path() {
  nix build --no-link --print-out-paths "nixpkgs#$1" 2>/dev/null | tail -n 1
}

list_timezones() {
  local values
  local file

  values=$(timedatectl list-timezones 2>/dev/null || true)
  if [[ -n "$values" ]]; then
    printf '%s\n' "$values"
    return
  fi

  file="${NOS_ZONE_TAB_FILE:-}"
  if [[ ! -f "$file" ]]; then
    file="$(nixpkgs_path tzdata)/share/zoneinfo/zone1970.tab"
  fi
  {
    printf 'UTC\n'
    awk '!/^#/ && NF >= 3 { print $3 }' "$file"
  } | sort -u
}

list_locales() {
  local file="${NOS_LOCALES_FILE:-}"
  if [[ ! -f "$file" ]]; then
    file="$(nixpkgs_path glibcLocales)/share/i18n/SUPPORTED"
  fi
  awk '$1 ~ /\.UTF-8\/UTF-8/ { sub(/\/UTF-8/, "", $1); print $1 }' "$file" | sort -u
}

list_keyboard_layouts() {
  local file="${NOS_XKB_RULES_FILE:-}"
  if [[ ! -f "$file" ]]; then
    file="$(nixpkgs_path xkeyboard_config)/share/xkeyboard-config-2/rules/base.lst"
  fi
  awk '
    /^! layout$/ { layouts = 1; next }
    /^!/ && layouts { exit }
    layouts && NF { print $1 }
  ' "$file"
}

# ╭──────────────────────────────────────────────────────────╮
# │ Value Helpers                                            │
# ╰──────────────────────────────────────────────────────────╯

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

# ╭──────────────────────────────────────────────────────────╮
# │ Host and User                                            │
# ╰──────────────────────────────────────────────────────────╯

print_heading "NixOS Host Configuration"

host_default=$(hostname -s 2>/dev/null || printf 'new-host')
host_name=$(ask "Hostname" "$host_default")
validate_name "$host_name" || {
  echo "Error: Host name may contain only letters, numbers, and hyphens." >&2
  exit 1
}
[[ "$host_name" != _* ]] || {
  echo "Error: Host name cannot begin with an underscore." >&2
  exit 1
}

host_dir="$hosts_dir/$host_name"
[[ ! -e "$host_dir" ]] || {
  echo "Error: Host configuration already exists: $host_dir" >&2
  echo "Existing host configurations are never replaced automatically." >&2
  exit 1
}

username_default="${SUDO_USER:-${USER:-cdt}}"
username=$(ask "Username" "$username_default")
validate_name "$username" || {
  echo "Error: User name may contain only letters, numbers, and hyphens." >&2
  exit 1
}

full_name=$(ask "Full name" "$username")
git_email=$(ask "Git email address" "$username@$(hostname -s)")
time_zone_default=$(timedatectl show -p Timezone --value 2>/dev/null || true)
time_zone=$(list_timezones | ask_list "Time zone" "${time_zone_default:-UTC}")
locale_default=$(localectl status 2>/dev/null | awk -F= '/System Locale: LANG=/ { print $2 }')
locale=$(list_locales | ask_list "System locale" "${locale_default:-en_US.UTF-8}")
keyboard_default=$(localectl status 2>/dev/null | awk '/X11 Layout:/ { print $3 }')
keyboard_layout=$(list_keyboard_layouts | ask_list "Keyboard layout" "${keyboard_default:-us}")
state_version_default=$(nixos-version 2>/dev/null | cut -d. -f1,2)
state_version=$(ask "NixOS state version" "${state_version_default:-26.05}")
home_directory="/home/$username"
flake_directory=$(ask "Configuration path on target" "/home/$username/NixOS")
firefox_profile_default="default"
firefox_profiles_file="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/profiles.ini"
if [[ -f "$firefox_profiles_file" ]]; then
  detected_firefox_profile=$(awk -F= '
    /^\[Profile/ {
      if (is_default && path != "") { print path; exit }
      is_default = 0
      path = ""
    }
    $1 == "Path" { path = $2 }
    $1 == "Default" && $2 == "1" { is_default = 1 }
    END { if (is_default && path != "") print path }
  ' "$firefox_profiles_file" | head -n 1)
  firefox_profile_default="${detected_firefox_profile:-default}"
fi
firefox_profile_path=$(ask "Firefox profile directory" "$firefox_profile_default")

command -v mkpasswd >/dev/null 2>&1 || {
  echo "Error: mkpasswd is required to create the initial login password hash." >&2
  echo "Install it temporarily with: nix shell nixpkgs#mkpasswd" >&2
  exit 1
}
while true; do
  read -r -s -p "Initial login password: " password
  printf '\n'
  read -r -s -p "Confirm login password: " password_confirm
  printf '\n'
  [[ -n "$password" ]] || {
    echo "Password cannot be empty." >&2
    continue
  }
  [[ "$password" == "$password_confirm" ]] && break
  echo "Passwords do not match. Please try again." >&2
done
initial_password_hash=$(printf '%s' "$password" | mkpasswd -m yescrypt -s)
unset password password_confirm

system_arch=$(uname -m)
case "$system_arch" in
  x86_64) system="x86_64-linux" ;;
  *)
    echo "Error: This configuration supports x86_64-linux only; detected $system_arch." >&2
    exit 1
    ;;
esac

# ╭──────────────────────────────────────────────────────────╮
# │ Hardware and Features                                    │
# ╰──────────────────────────────────────────────────────────╯

print_heading "Hardware and Optional Features"
if [[ -d /sys/firmware/efi ]]; then
  boot_default=1
else
  boot_default=2
fi
boot_mode=$(ask_choice "Boot mode" "$boot_default" uefi bios)
if [[ "$boot_mode" == bios ]]; then
  boot_device=$(ask "GRUB install device" "/dev/sda")
else
  boot_device=""
fi

gpu=$(ask_choice "Graphics hardware" 1 none nvidia amd intel)
nvidia_open=false
nvidia_prime_value=null
if [[ "$gpu" == nvidia ]]; then
  if ask_yes_no "Enable NVIDIA open kernel modules" n; then
    nvidia_open=true
  fi
  if ask_yes_no "Configure hybrid NVIDIA PRIME graphics" n; then
    integrated_gpu=$(ask_choice "Integrated graphics hardware" 1 intel amd)
    integrated_bus_id=$(ask "Integrated GPU bus ID" "PCI:0:2:0")
    nvidia_bus_id=$(ask "NVIDIA GPU bus ID" "PCI:1:0:0")
    [[ "$integrated_bus_id" =~ ^PCI:[0-9]+:[0-9]+:[0-9]+$ ]] || {
      echo "Error: Integrated GPU bus ID must use the PCI:<bus>:<device>:<function> format." >&2
      exit 1
    }
    [[ "$nvidia_bus_id" =~ ^PCI:[0-9]+:[0-9]+:[0-9]+$ ]] || {
      echo "Error: NVIDIA GPU bus ID must use the PCI:<bus>:<device>:<function> format." >&2
      exit 1
    }
    nvidia_prime_value="{ integratedGpu = \"$integrated_gpu\"; integratedBusId = \"$integrated_bus_id\"; nvidiaBusId = \"$nvidia_bus_id\"; offload = true; }"
  fi
fi

if ask_yes_no "Enable Steam and gaming support" y; then
  gaming=true
else
  gaming=false
fi

if ask_yes_no "Enable battery management" "$(if compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then echo y; else echo n; fi)"; then
  battery=true
else
  battery=false
fi

if ask_yes_no "Enable Bluetooth support" y; then
  bluetooth=true
else
  bluetooth=false
fi

if ask_yes_no "Enable PipeWire audio" y; then
  audio=true
else
  audio=false
fi

if ask_yes_no "Enable Docker" y; then
  docker=true
else
  docker=false
fi

windows=false
if [[ "$docker" == true ]]; then
  if ask_yes_no "Enable Windows VM support" n; then
    windows=true
  fi
fi

if ask_yes_no "Enable 1Password and SSH agent integration" y; then
  onepassword=true
else
  onepassword=false
fi

if ask_yes_no "Enable printing support" y; then
  printing=true
else
  printing=false
fi

deep_sleep=false
thermald=false
if [[ "$battery" == true ]]; then
  if ask_yes_no "Use deep suspend by default" n; then
    deep_sleep=true
  fi
  if grep -qi 'GenuineIntel' /proc/cpuinfo 2>/dev/null && ask_yes_no "Enable Intel thermald" y; then
    thermald=true
  fi
fi

if ask_yes_no "Configure trackpad input" n; then
  trackpad=true
  trackpad_name=$(ask "Hyprland trackpad device name" "")
else
  trackpad=false
  trackpad_name=""
fi

# ╭──────────────────────────────────────────────────────────╮
# │ Confirmation                                             │
# ╰──────────────────────────────────────────────────────────╯

print_heading "Configuration Summary"

printf 'Identity\n'
printf '  Hostname:                    %s\n' "$host_name"
printf '  Username:                    %s\n' "$username"
printf '  Full name:                   %s\n' "$full_name"
printf '  Git email address:           %s\n' "$git_email"
printf '  Home directory:              %s\n' "$home_directory"
printf '  Initial login password:      Configured\n'

printf '\nRegional Settings\n'
printf '  Time zone:                   %s\n' "$time_zone"
printf '  System locale:               %s\n' "$locale"
printf '  Keyboard layout:             %s\n' "$keyboard_layout"

printf '\nSystem\n'
printf '  Platform:                    %s\n' "$system"
printf '  NixOS state version:         %s\n' "$state_version"
printf '  Configuration path:          %s\n' "$flake_directory"
printf '  Firefox profile directory:   %s\n' "$firefox_profile_path"
printf '  Hardware scan root:          %s\n' "${root_args[1]:-/}"
printf '  Boot mode:                   %s\n' "$(choice_label "$boot_mode")"
if [[ "$boot_mode" == bios ]]; then
  printf '  GRUB installation device:    %s\n' "$boot_device"
fi

printf '\nGraphics\n'
printf '  Primary graphics hardware:   %s\n' "$(choice_label "$gpu")"
if [[ "$gpu" == nvidia ]]; then
  printf '  NVIDIA open modules:         %s\n' "$(status_label "$nvidia_open")"
  printf '  NVIDIA PRIME:                %s\n' "$(if [[ "$nvidia_prime_value" != null ]]; then printf 'Enabled'; else printf 'Disabled'; fi)"
  if [[ "$nvidia_prime_value" != null ]]; then
    printf '  Integrated graphics:         %s\n' "$(choice_label "$integrated_gpu")"
    printf '  Integrated GPU bus ID:       %s\n' "$integrated_bus_id"
    printf '  NVIDIA GPU bus ID:           %s\n' "$nvidia_bus_id"
    printf '  PRIME offload:               Enabled\n'
  fi
fi

printf '\nOptional Features\n'
printf '  Steam and gaming:            %s\n' "$(status_label "$gaming")"
printf '  Battery management:          %s\n' "$(status_label "$battery")"
printf '  Deep suspend:                %s\n' "$(status_label "$deep_sleep")"
printf '  Intel thermald:              %s\n' "$(status_label "$thermald")"
printf '  Bluetooth:                   %s\n' "$(status_label "$bluetooth")"
printf '  PipeWire audio:              %s\n' "$(status_label "$audio")"
printf '  Docker:                      %s\n' "$(status_label "$docker")"
printf '  Windows VM:                  %s\n' "$(status_label "$windows")"
printf '  1Password and SSH agent:     %s\n' "$(status_label "$onepassword")"
printf '  Printing:                    %s\n' "$(status_label "$printing")"
printf '  Trackpad input:              %s\n' "$(status_label "$trackpad")"
if [[ "$trackpad" == true ]]; then
  printf '  Trackpad device name:        %s\n' "${trackpad_name:-Automatic}"
fi
printf '\n'

if ! ask_yes_no "Create this host configuration" y; then
  echo "Configuration cancelled." >&2
  exit 0
fi

printf 'Creating host configuration...\n'

# ╭──────────────────────────────────────────────────────────╮
# │ Host Files                                               │
# ╰──────────────────────────────────────────────────────────╯

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
escaped_firefox_profile=$(nix_string_replacement "$firefox_profile_path")
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
  -e "s|firefoxProfilePath = \"default\";|firefoxProfilePath = \"$escaped_firefox_profile\";|" \
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

# ╭──────────────────────────────────────────────────────────╮
# │ Hardware Configuration                                   │
# ╰──────────────────────────────────────────────────────────╯

printf 'Generating hardware configuration...\n'
sudo nixos-generate-config "${root_args[@]}" --show-hardware-config > "$hardware_tmp"

if ! grep -qE '^\{[[:space:]]*$' "$hardware_tmp" || ! tail -n 1 "$hardware_tmp" | grep -qE '^\}[[:space:]]*$'; then
  echo "Error: nixos-generate-config returned an unexpected hardware configuration." >&2
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

# Make generated host visible to Git-backed flake evaluation without staging
# file contents. Ignored .env remains outside the flake source.
git -C "$repo_dir" add -N -- "hosts/$host_name"

# ╭──────────────────────────────────────────────────────────╮
# │ Local Environment                                        │
# ╰──────────────────────────────────────────────────────────╯

env_file="$repo_dir/.env"
env_created=false
if [[ ! -e "$env_file" ]]; then
  printf 'export HOST_NAME=%s\n' "$host_name" > "$env_file"
  env_created=true
fi

# ╭──────────────────────────────────────────────────────────╮
# │ Completion                                               │
# ╰──────────────────────────────────────────────────────────╯

print_heading "Host Configuration Created"
printf 'Host configuration:     %s\n' "$host_file"
printf 'Hardware configuration: %s\n' "$hardware_file"
if [[ "$env_created" == true ]]; then
  printf 'Local environment:      %s\n' "$env_file"
else
  printf 'Local environment:      %s (existing file preserved)\n' "$env_file"
fi
print_heading "Next Steps"
printf 'Apply configuration:\n'
printf '  sudo nixos-rebuild switch --flake %s#%s\n' "$flake_directory" "$host_name"

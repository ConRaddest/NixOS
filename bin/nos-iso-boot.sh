#!/usr/bin/env bash
set -euo pipefail

entry_id=nos-iso.conf
esp_dir=/boot/EFI/nos-iso
entry_file="/boot/loader/entries/$entry_id"

usage() {
  cat <<'EOF'
Usage: nos iso-boot <arch-based-installer.iso>
       nos iso-boot --remove

Prepare a one-time native boot of an ArchISO-compatible installer through
systemd-boot. Native boot lets installer detect physical hardware.
EOF
}

if (($# != 1)); then
  usage >&2
  exit 2
fi

if [[ $1 == --remove ]]; then
  sudo rm -rf -- "$esp_dir"
  sudo rm -f -- "$entry_file"
  printf 'Removed native ISO boot files.\n'
  exit 0
fi

iso=$(readlink -f -- "$1")
if [[ ! -f "$iso" || ! -r "$iso" ]]; then
  printf 'ISO is not a readable file: %s\n' "$1" >&2
  exit 1
fi

if [[ $iso == *[[:space:]]* ]]; then
  printf 'ISO path cannot contain whitespace: %s\n' "$iso" >&2
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  printf 'This command requires UEFI.\n' >&2
  exit 1
fi

if ! sudo test -d /boot/loader/entries; then
  printf 'This command requires systemd-boot mounted at /boot.\n' >&2
  exit 1
fi

kernel_path=arch/boot/x86_64/vmlinuz-linux-t2
initrd_path=arch/boot/x86_64/initramfs-linux-t2.img
if ! bsdtar -tf "$iso" | grep -Fxq "$kernel_path" ||
  ! bsdtar -tf "$iso" | grep -Fxq "$initrd_path"; then
  printf 'ISO does not contain expected Omarchy ArchISO boot files.\n' >&2
  exit 1
fi

iso_source=$(findmnt -nro SOURCE -T "$iso")
iso_uuid=$(findmnt -nro UUID -T "$iso")
iso_mount=$(findmnt -nro TARGET -T "$iso")
if [[ $iso_source != /dev/* || -z $iso_uuid ]]; then
  printf 'ISO must be stored on a directly discoverable disk filesystem.\n' >&2
  exit 1
fi

if [[ $iso_mount == / ]]; then
  img_loop=$iso
else
  img_loop=/${iso#"$iso_mount"/}
fi

work_dir=$(mktemp -d)
cleanup() {
  local status=$?
  trap - EXIT INT TERM
  rm -rf -- "$work_dir"
  exit "$status"
}
trap cleanup EXIT INT TERM

printf 'Extracting native boot files from %s...\n' "$iso"
bsdtar -xOf "$iso" "$kernel_path" >"$work_dir/vmlinuz"
bsdtar -xOf "$iso" "$initrd_path" >"$work_dir/initramfs.img"

required_bytes=$(du -cb "$work_dir/vmlinuz" "$work_dir/initramfs.img" | tail -1 | cut -f1)
available_bytes=$(df -B1 --output=avail /boot | tail -1 | tr -d ' ')
if ((required_bytes > available_bytes)); then
  printf 'Not enough free space on /boot: need %s bytes, have %s.\n' \
    "$required_bytes" "$available_bytes" >&2
  exit 1
fi

sudo install -d -m 0755 -- "$esp_dir" /boot/loader/entries
sudo install -m 0644 -- "$work_dir/vmlinuz" "$esp_dir/vmlinuz"
sudo install -m 0644 -- "$work_dir/initramfs.img" "$esp_dir/initramfs.img"

entry=$(cat <<EOF
title Omarchy native ISO installer
linux /EFI/nos-iso/vmlinuz
initrd /EFI/nos-iso/initramfs.img
options archisobasedir=arch img_dev=UUID=$iso_uuid img_loop=$img_loop quiet splash xe.enable_panel_replay=0 initramfs_async=0
EOF
)
printf '%s\n' "$entry" | sudo tee "$entry_file" >/dev/null
sudo bootctl set-oneshot "$entry_id"

printf '\nNative ISO boot prepared. Next reboot will start installer once.\n'
printf 'ISO remains at %s; do not move or delete it yet.\n' "$iso"
printf 'Run nos iso-boot --remove from NixOS after installation.\n'

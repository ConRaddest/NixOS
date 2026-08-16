#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: nos iso-install <installer.iso> <target-disk>

Boot an ISO in a UEFI QEMU VM and expose a physical disk to its installer.
The target must be a whole disk, for example /dev/nvme1n1 or /dev/sdb.

Optional environment variables:
  QEMU_MEMORY  Guest memory (default: 8G)
  QEMU_CPUS    Guest CPU count (default: up to 6)
EOF
}

parent_disk() {
  local device parent
  device=$(readlink -f -- "$1")

  while parent=$(lsblk -dnro PKNAME -- "$device") && [[ -n "$parent" ]]; do
    device="/dev/$parent"
  done

  readlink -f -- "$device"
}

if (($# != 2)); then
  usage >&2
  exit 2
fi

iso=$(readlink -f -- "$1")
target=$(readlink -f -- "$2")

if [[ ! -f "$iso" || ! -r "$iso" ]]; then
  printf 'ISO is not a readable file: %s\n' "$1" >&2
  exit 1
fi

if [[ ! -b "$target" ]]; then
  printf 'Target is not a block device: %s\n' "$2" >&2
  exit 1
fi

if [[ $(lsblk -dnro TYPE -- "$target") != disk ]]; then
  printf 'Target must be a whole disk, not a partition: %s\n' "$target" >&2
  exit 1
fi

root_source=$(findmnt -nro SOURCE /)
root_disk=$(parent_disk "$root_source")
if [[ "$target" == "$root_disk" ]]; then
  printf 'Refusing to expose current system disk: %s\n' "$target" >&2
  exit 1
fi

iso_source=$(findmnt -nro SOURCE -T "$iso")
if [[ "$iso_source" == /dev/* ]] && [[ "$target" == "$(parent_disk "$iso_source")" ]]; then
  printf 'ISO is stored on target disk. Move it to another disk first.\n' >&2
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  printf 'This script supports UEFI hosts only.\n' >&2
  exit 1
fi

firmware_code="$QEMU_FIRMWARE_DIR/edk2-x86_64-code.fd"
firmware_vars="$QEMU_FIRMWARE_DIR/edk2-i386-vars.fd"
if [[ ! -r "$firmware_code" || ! -r "$firmware_vars" ]]; then
  printf 'QEMU UEFI firmware files not found in %s\n' "$QEMU_FIRMWARE_DIR" >&2
  exit 1
fi

printf 'ISO:         %s\n' "$iso"
printf 'System disk: %s\n' "$root_disk"
printf 'TARGET DISK: %s\n\n' "$target"
lsblk -o NAME,SIZE,MODEL,TYPE,FSTYPE,MOUNTPOINTS -- "$target"
printf '\nInstaller may erase all data on %s.\n' "$target"
printf 'Type ERASE %s to continue: ' "$target"
IFS= read -r confirmation
if [[ "$confirmation" != "ERASE $target" ]]; then
  printf 'Cancelled.\n'
  exit 1
fi

# Unmount target and all child partitions, deepest first.
mapfile -t target_devices < <(lsblk -lnpo NAME -- "$target" | tac)
for device in "${target_devices[@]}"; do
  if findmnt -rn -S "$device" >/dev/null; then
    sudo umount -- "$device"
  fi
done

cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/qemu
mkdir -p -- "$cache_dir"
vars_file=$(mktemp --tmpdir="$cache_dir" iso-installer-vars.XXXXXX.fd)
cp -- "$firmware_vars" "$vars_file"
chmod u+w -- "$vars_file"

acl_user=$(id -un)
acl_added=false
cleanup() {
  local status=$?
  trap - EXIT INT TERM
  rm -f -- "$vars_file"
  if [[ "$acl_added" == true ]]; then
    sudo setfacl -x "u:$acl_user" -- "$target" || true
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

sudo setfacl -m "u:$acl_user:rw" -- "$target"
acl_added=true

cpus=${QEMU_CPUS:-$(nproc)}
if ((cpus > 6)); then
  cpus=6
fi
memory=${QEMU_MEMORY:-8G}

disk_args=(-drive "file=$target,if=none,id=target,format=raw,cache=none")
if [[ $(basename -- "$target") == nvme* ]]; then
  disk_args+=(-device "nvme,drive=target,serial=INSTALLTARGET")
else
  disk_args+=(-device "virtio-blk-pci,drive=target")
fi

printf '\nStarting installer. Shut down VM after installation; do not restart it.\n'
qemu-system-x86_64 \
  -machine q35,accel=kvm \
  -cpu host \
  -m "$memory" \
  -smp "$cpus" \
  -drive "if=pflash,format=raw,readonly=on,file=$firmware_code" \
  -drive "if=pflash,format=raw,file=$vars_file" \
  -cdrom "$iso" \
  "${disk_args[@]}" \
  -nic user,model=virtio-net-pci \
  -boot order=d,menu=on

printf '\nInstaller VM stopped. Reboot and select target disk from firmware boot menu.\n'

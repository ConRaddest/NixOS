# NixOS configuration

Multi-host NixOS and Home Manager configuration for x86_64 Linux workstations. Configuration provides Hyprland through UWSM, DankMaterialShell, PipeWire, optional hardware/services, development tools, desktop applications, and per-host Home Manager profiles.

Reader is expected to understand Linux block devices, filesystems, boot modes, Git, and basic NixOS administration.

## Contents

- [Scope and assumptions](#scope-and-assumptions)
- [Repository model](#repository-model)
- [Fresh NixOS installation](#fresh-nixos-installation)
- [Adopting an existing NixOS installation](#adopting-an-existing-nixos-installation)
- [Host configuration reference](#host-configuration-reference)
- [Hardware and optional modules](#hardware-and-optional-modules)
- [Home Manager and desktop configuration](#home-manager-and-desktop-configuration)
- [Per-host applications](#per-host-applications)
- [Local environment and secrets](#local-environment-and-secrets)
- [Helper commands](#helper-commands)
- [Validation, updates, and rollback](#validation-updates-and-rollback)
- [Troubleshooting](#troubleshooting)

## Scope and assumptions

Current support boundary:

- `x86_64-linux` only
- NixOS and Home Manager release `26.05`
- UEFI with systemd-boot or legacy BIOS with GRUB
- Hyprland Wayland session started through UWSM
- one primary user per host definition
- host checkout normally stored at `/home/<user>/NixOS`
- standalone Home Manager output is available, but Home Manager is also integrated into every NixOS host

This is workstation configuration, not minimal server configuration. Base host template installs desktop, shell, development, browser, portal, theming, and application modules. Remove unwanted imports from host file when targeting a minimal machine.

No display manager is enabled. After logging into a TTY, start Hyprland with:

```bash
startw
```

`startw` expands to `uwsm start hyprland-uwsm.desktop`.

## Repository model

### Layout

```text
.
├── flake.nix
├── flake.lock
├── hosts
│   ├── _template
│   │   ├── apps.txt
│   │   ├── hardware.nix
│   │   └── host.nix
│   └── <host>
│       ├── apps.txt
│       ├── hardware.nix
│       └── host.nix
└── modules
    ├── home
    └── system
```

`import-tree` loads system modules, home modules, and host definitions automatically. Directories beginning with `_`, including `hosts/_template`, are templates and do not create flake outputs.

Each real `hosts/<host>` directory exports:

```text
nixosConfigurations.<host>
homeConfigurations.<user>@<host>
nixosModules.<host>Configuration
nixosModules.<host>Hardware
```

List available outputs:

```bash
nix flake show path:.
```

### Host selection

All host definitions coexist in flake. Local ignored `.env` selects target used by helper commands:

```bash
export HOST_NAME=legion
```

`HOST_NAME` does not filter flake imports or outputs. It tells `nos-build`, `nos-update`, `nos-refresh`, `nos-install`, and `nos-remove` which existing output belongs to current machine.

Helper scripts read only `HOST_NAME` when selecting host. They build `path:$NOS_DIR`, so newly generated, untracked host files are visible to Nix without staging them in Git.

### Integrated and standalone Home Manager

NixOS host imports Home Manager NixOS module and applies `homeConfig` during system rebuild:

```bash
sudo nixos-rebuild switch --flake path:.#<host>
```

Same profile is also exported standalone:

```bash
home-manager switch --flake path:.#<user>@<host>
```

Normal operation should use system rebuild. Standalone output is useful for testing or applying home-only changes.

## Fresh NixOS installation

### 1. Boot installer in correct firmware mode

Boot NixOS installer in same mode intended for installed system:

```bash
test -d /sys/firmware/efi && echo UEFI || echo BIOS
```

Wizard detects current installer mode as default. Do not select UEFI unless EFI System Partition is mounted at `/mnt/boot`. Do not select BIOS unless GRUB target is whole disk such as `/dev/sda` or `/dev/nvme0n1`, not partition.

### 2. Connect network and verify clock

For Wi-Fi, use `nmtui`, `nmcli`, or `iwctl`, depending on installer image. Verify connectivity and time:

```bash
ping -c 3 cache.nixos.org
timedatectl status
```

### 3. Partition, format, and mount target

Partitioning is intentionally not automated. Create layout required by machine, then mount final root at `/mnt` before running host wizard.

Typical UEFI layout:

```text
EFI System Partition   FAT32   mounted at /mnt/boot
swap                   swap    activated with swapon
root                   ext4    mounted at /mnt
```

Typical BIOS layout:

```text
BIOS boot partition    EF02/bios_grub when using GPT
swap                   swap
root                   ext4 mounted at /mnt
```

Inspect result:

```bash
findmnt -R /mnt
lsblk -f
swapon --show
```

Encrypted disks, LVM, RAID, Btrfs subvolumes, impermanence, and additional filesystems are supported only insofar as they are already mounted correctly when `nixos-generate-config` runs. Review generated hardware file carefully for these layouts.

> **Destructive-action warning:** partitioning and formatting erase data. Verify every device path with `lsblk` before running tools such as `parted`, `fdisk`, `mkfs`, or `mkswap`.

### 4. Obtain repository and dependencies

Clone into temporary installer location or directly below `/mnt`:

```bash
nix shell nixpkgs#git nixpkgs#mkpasswd
git clone <repository-url> NixOS
cd NixOS
```

`nixos-generate-config` and `sudo` are supplied by NixOS installer. Wizard additionally requires Git and `mkpasswd`.

### 5. Generate host

Run wizard from repository root with installed system mounted at `/mnt`:

```bash
./modules/system/scripts/nos-new-host.sh --root /mnt
```

If `nos-new-host` is already available in current profile, equivalent command is:

```bash
nos-new-host --root /mnt
```

Wizard asks for:

- hostname and username
- full name and Git email
- timezone, locale, keyboard layout
- NixOS state version
- final checkout path on installed system
- initial login password
- UEFI or BIOS boot mode
- graphics driver and optional NVIDIA configuration
- Steam/gaming support
- battery, Bluetooth, audio, Docker, Windows VM, 1Password, printing, and trackpad support

Generated files:

```text
hosts/<host>/host.nix
hosts/<host>/hardware.nix
hosts/<host>/apps.txt
```

Wizard refuses to overwrite existing host directory.

#### State version on fresh installation

For genuinely fresh installation, use release being installed, normally wizard default. `stateVersion` controls compatibility defaults; it is not update channel selector.

#### NVIDIA PRIME bus IDs

For hybrid NVIDIA graphics, wizard expects NixOS decimal bus IDs:

```text
PCI:<bus>:<device>:<function>
```

`lspci` prints hexadecimal IDs. Convert each component to decimal. Examples:

```text
00:02.0 -> PCI:0:2:0
01:00.0 -> PCI:1:0:0
0a:00.0 -> PCI:10:0:0
```

Do not accept default PRIME IDs unless they match hardware.

### 6. Review generated host

At minimum inspect:

```bash
$EDITOR hosts/<host>/host.nix
$EDITOR hosts/<host>/hardware.nix
$EDITOR hosts/<host>/apps.txt
```

Verify:

- root and boot filesystem UUIDs
- swap UUID
- `nixpkgs.hostPlatform`
- CPU microcode line
- boot mode and BIOS GRUB device
- graphics driver selection
- NVIDIA open-module setting and PRIME IDs
- final `flakeDirectory`
- username/home path
- state version
- enabled optional modules

List/evaluate outputs before installation:

```bash
nix flake show path:.
nix flake check --no-build path:.
nix eval --raw path:.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

Build without installing:

```bash
nix build --no-link path:.#nixosConfigurations.<host>.config.system.build.toplevel
```

### 7. Preserve generated checkout on target

If repository currently lives outside `/mnt`, copy it to configured target location before installation. Example for `/home/alice/NixOS`:

```bash
sudo mkdir -p /mnt/home/alice
sudo cp -a . /mnt/home/alice/NixOS
cd /mnt/home/alice/NixOS
```

Use copied checkout for install, ensuring generated host files are included even when uncommitted.

### 8. Install

From target checkout:

```bash
sudo nixos-install --flake "path:$PWD#<host>"
```

System configuration includes Home Manager profile. Separate `home-manager switch` is unnecessary.

After installation, set checkout ownership from installed environment:

```bash
sudo nixos-enter --root /mnt -c 'chown -R <user>:users /home/<user>/NixOS'
```

Create local host selector now or after reboot:

```bash
printf 'export HOST_NAME=%s\n' '<host>' | sudo tee /mnt/home/<user>/NixOS/.env >/dev/null
sudo chmod 600 /mnt/home/<user>/NixOS/.env
sudo nixos-enter --root /mnt -c 'chown <user>:users /home/<user>/NixOS/.env'
```

### 9. Reboot and start session

```bash
cd /
sudo umount -R /mnt
sudo reboot
```

Log in through TTY using initial password, then start desktop:

```bash
startw
```

NetworkManager is enabled; use DMS/desktop controls, `nmcli`, or `nmtui` for persistent connections.

### 10. Remove bootstrap password hash

Generated yescrypt hash is stored in host source and Nix store. After first successful login:

1. Set final password with `passwd`.
2. Change `initialHashedPassword` in `hosts/<host>/host.nix` to `null`.
3. Rebuild.
4. Do not commit bootstrap hash.

```bash
passwd
$EDITOR hosts/<host>/host.nix
nos-build
```

`initialHashedPassword` is intended only for account creation. Leaving hash in Git permits offline password guessing.

## Adopting an existing NixOS installation

Migration changes system packages, user shell, desktop stack, portals, Home Manager-managed files, and optional services. Build first; switch only after reviewing closure and generated hardware.

### 1. Back up current configuration and state

```bash
sudo cp -a /etc/nixos /etc/nixos.backup-$(date +%Y%m%d-%H%M%S)
```

Also back up mutable home configuration that may become Home Manager-owned:

```bash
mkdir -p ~/config-backup
cp -a ~/.config ~/.local/state ~/config-backup/ 2>/dev/null || true
```

Record:

```bash
nixos-version
grep -R 'system.stateVersion' /etc/nixos
findmnt -R /
lsblk -f
```

### 2. Clone repository at final path

```bash
git clone <repository-url> ~/NixOS
cd ~/NixOS
nix shell nixpkgs#mkpasswd
```

If repository already exists elsewhere, either move it to final path or enter exact existing path when wizard asks for target config path.

### 3. Generate host from running system

Run without `--root`:

```bash
./modules/system/scripts/nos-new-host.sh
```

Wizard runs `nixos-generate-config --show-hardware-config` against current machine.

When asked for state version, enter original value from existing configuration, not current channel version. Existing machine installed with `23.11` should normally retain `23.11` even when running newer NixOS.

Wizard requires initial password input because same workflow supports fresh installations. For existing user, edit generated host immediately afterward:

```nix
initialHashedPassword = null;
```

Existing password remains managed by mutable user database.

### 4. Merge existing system-specific settings

Compare:

```bash
diff -u /etc/nixos/hardware-configuration.nix hosts/<host>/hardware.nix
```

Preserve any settings not rediscovered automatically:

- LUKS devices and keyfiles
- Btrfs subvolumes and mount options
- RAID/LVM declarations
- special kernel modules or parameters
- ZFS host ID and pools
- custom initrd networking
- additional filesystems
- swap files and resume offsets
- CPU microcode
- virtualization/IOMMU settings
- secure boot or alternative bootloader configuration

Default boot module supports only:

- `nos.boot.mode = "uefi"` using systemd-boot
- `nos.boot.mode = "bios"` using GRUB and `nos.boot.device`

If existing machine uses Lanzaboote, GRUB on EFI, rEFInd, mirrored boot devices, or custom boot flow, replace `self.nixosModules.boot` import or adjust `modules/system/boot.nix` before first switch.

### 5. Review account and Home Manager impact

Generated user definition changes login shell to Fish and adds groups according to enabled services. Home Manager will own many files under:

```text
~/.config
~/.local/share
~/.mozilla
~/.npmrc
~/.pi
~/.ssh
```

Home Manager normally aborts on conflicting unmanaged files rather than deleting them. Move reported files aside, then rebuild. DMS wallpaper target `~/Pictures/Wallpapers/sunset-lake.png` is force-managed and can replace same path.

If existing Home Manager uses older `home.stateVersion`, current host model shares one `stateVersion` between NixOS and Home Manager. Preserve more conservative/original value or split fields manually before migration.

### 6. Configure host selector

```bash
cp .env.example .env
$EDITOR .env
chmod 600 .env
```

Minimum content:

```bash
export HOST_NAME=<host>
```

### 7. Evaluate and build safely

```bash
nix flake show path:.
nix flake check --no-build path:.
nix build path:.#nixosConfigurations.<host>.config.system.build.toplevel
```

Inspect closure difference:

```bash
nix store diff-closures /run/current-system ./result
```

Build standalone Home Manager profile if isolating home failures:

```bash
nix build path:.#homeConfigurations.<user>@<host>.activationPackage
```

### 8. Stage activation

Safest first deployment writes boot entry without changing running system:

```bash
sudo nixos-rebuild boot --flake path:.#<host>
sudo reboot
```

For immediate activation:

```bash
sudo nixos-rebuild switch --flake path:.#<host>
```

Home Manager activates as part of NixOS switch.

### 9. Confirm services and desktop

After reboot:

```bash
systemctl --failed
systemctl --user --failed
journalctl -b -p warning
```

Start Hyprland from TTY:

```bash
startw
```

Verify displays, portals, audio, Bluetooth, suspend, graphics, Docker, and user services before deleting old `/etc/nixos` backup.

## Host configuration reference

Primary host data lives in `hosts/<host>/host.nix`.

### Identity and paths

```nix
host = {
  system = "x86_64-linux";
  username = "alice";
  fullName = "Alice Example";
  homeDirectory = "/home/alice";
  flakeDirectory = "/home/alice/NixOS";
  stateVersion = "26.05";
  initialHashedPassword = null;
  gaming = true;
};
```

- `system`: currently must be `x86_64-linux`.
- `username`: NixOS user and standalone Home Manager output prefix.
- `homeDirectory`: must match actual account home.
- `flakeDirectory`: mutable checkout used by helper commands and Windows credential location.
- `stateVersion`: compatibility baseline; never bump merely because inputs update.
- `initialHashedPassword`: bootstrap only; use `null` after account exists.
- `gaming`: controls Steam launcher exposure; system Steam support also requires gaming system module import.

### Boot

```nix
boot = {
  mode = "uefi"; # or "bios"
  device = null;  # BIOS example: "/dev/sda"
};
```

UEFI enables systemd-boot and EFI variable writes. BIOS enables GRUB and requires whole-disk `device`.

### Hardware behavior

```nix
hardware = {
  deepSleep = false;
  thermald = false;
  nvidiaOpen = false;
  nvidiaPrime = null;
};
```

- `deepSleep`: adds `mem_sleep_default=deep`. Confirm firmware exposes deep sleep:

  ```bash
  cat /sys/power/mem_sleep
  ```

- `thermald`: enable only on supported Intel systems.
- `nvidiaOpen`: selects NVIDIA open kernel modules; suitability depends on GPU generation and driver.
- `nvidiaPrime`: optional hybrid graphics configuration:

  ```nix
  nvidiaPrime = {
    integratedGpu = "intel"; # or "amd"
    integratedBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
    offload = true;
  };
  ```

### Region and local hosts

```nix
region = {
  timeZone = "Europe/Berlin";
  locale = "en_US.UTF-8";
  keyboardLayout = "us";
};

localHosts = [
  "api-local.example.test"
];
```

`localHosts` entries map to both `127.0.0.1` and `::1`.

### Git identity

```nix
git = {
  name = "Alice Example";
  email = "alice@example.com";
};
```

### Monitors and workspaces

Empty monitor list leaves output mode selection to Hyprland:

```nix
monitors = [ ];
```

Explicit layout:

```nix
monitors = [
  {
    output = "eDP-1";
    mode = "1920x1080@60";
    position = "0x0";
    scale = 1;
    workspaces = [ 1 2 3 ];
  }
  {
    output = "DP-1";
    mode = "2560x1440@144";
    position = "1920x0";
    scale = 1;
    workspaces = [ 4 5 6 7 8 9 ];
  }
];
```

Discover names and modes after starting Hyprland:

```bash
hyprctl monitors all
```

Unknown/unconfigured outputs use Hyprland defaults. Workspace scrolling falls back to workspaces 1–9 when active monitor has no explicit assignment.

### Trackpad

Home config contains:

```nix
nos = {
  trackpad = true;
  trackpadName = "device-name-from-hyprctl";
};
```

Discover exact name:

```bash
hyprctl devices
```

When enabled, config adds three-finger vertical workspace gesture and device-specific natural scrolling.

### Firefox development CA

```nix
firefoxCertificatePath = "/home/alice/.local/share/mkcert/rootCA.pem";
```

Set `null` when no local CA should be installed. Non-null path must exist on target before Firefox consumes policy. Generate with `mkcert` when required.

### Utility and VM sizing

```nix
gduMaxCores = 8;

windows = {
  timeZone = "Europe/Berlin";
  memory = "8G";
  cpuCores = 6;
  diskSize = "96G";
};
```

Windows settings feed Dockur Windows compose file. Ensure host has enough free RAM, CPU, and disk.

## Hardware and optional modules

### Core system modules

Every generated host imports:

- `options`: shared `nos.boot` and `nos.hardware` options
- `boot`: systemd-boot or GRUB selection
- `core`: quiet boot parameters and PCI/USB tools
- `rsa`: host-defined locale, timezone, keyboard
- `networking`: NetworkManager, systemd-resolved, local host aliases
- `nix`: flakes, optimization, garbage collection, unfree packages
- `security`: user, Fish shell, sudo, Polkit
- `vscode`: `nix-ld` libraries for extension binaries
- `hyprland`: Hyprland, XWayland, UWSM
- `portals`: GTK, Hyprland, and terminal file chooser portals

### Graphics

Choose at most one primary module unless configuring NVIDIA PRIME:

- `amd`: Mesa graphics, 32-bit graphics, amdgpu initrd
- `intel`: Mesa graphics, Intel media driver, 32-bit media driver
- `nvidia`: proprietary/open selection, modesetting, power management, optional PRIME
- none: useful for VMs, headless systems, or hardware handled by base NixOS

Hybrid NVIDIA imports NVIDIA plus integrated Intel/AMD module. Validate PRIME bus IDs before switching.

Gaming is separate:

```nix
self.nixosModules.gaming
```

It enables NixOS Steam support. `host.gaming` controls Home Manager launcher. Keep both aligned.

### Optional module pairs

Wizard keeps these aligned:

| Capability | System module | Home module | Notes |
|---|---|---|---|
| Audio | `audio` | `audio` | PipeWire, ALSA, Pulse compatibility, controls |
| Battery | `battery` | `battery` | Power profiles, UPower, brightness controls |
| Bluetooth | `bluetooth` | `bluetooth` | bluetoothd, rfkill unblock, Bluetui |
| Docker | `docker` | `lazydocker` | Docker daemon, TUN module, LazyDocker |
| Windows VM | Docker dependency | `windows` | KVM/TUN, Docker Compose, FreeRDP |
| 1Password | `onepassword` | `ssh` | GUI/CLI and SSH agent socket |
| Printing | `printing` | none | CUPS |

Manual imports should preserve same dependencies.

### Windows VM

When enabled, Home Manager creates:

```text
~/.config/windows/docker-compose.yaml
~/VMs/windows/storage
~/Windows
```

Commands:

```bash
windows-install
windows-vm-start
windows-vm-rdp
windows-uninstall
```

Requirements:

- Docker module enabled
- `/dev/kvm` available
- `/dev/net/tun` available
- user in `docker` and `kvm` groups
- local ports free: `8006`, `3389/tcp`, `3389/udp`, `11433/tcp`

`windows-install` writes credentials to checkout `.env`, pulls `dockurr/windows:latest`, and starts installer. Web installer is available at `http://localhost:8006`.

`windows-uninstall` can permanently remove VM disk, shared folder, container, image, and credentials. Read prompt paths before confirmation.

## Home Manager and desktop configuration

### Core home profile

Base profile includes:

- Fish, Starship, zoxide, fzf
- Kitty
- Git
- Neovim
- Node.js/npm mutable link prefix
- .NET 10, Python, language servers, formatters
- Fastfetch, GDU, Yazi, btop
- Firefox
- Pi coding agent and local extensions
- XDG user directories and MIME defaults

### Desktop stack

- Hyprland through UWSM
- DankMaterialShell systemd user service
- GTK/Qt appearance
- dynamic Matugen templates
- screen-share picker
- XDG portals and terminal Yazi file chooser
- Polkit agent
- clipboard, screenshots, color picker

DMS generates runtime themes for:

- btop
- fzf
- Starship
- Yazi
- Neovim
- screen-share picker

Initial DMS startup may briefly precede generated theme files. Service regenerates templates once DMS IPC becomes available.

### Hyprland source

Main Lua config is store-managed from:

```text
modules/home/hyprland/hyprland.lua
```

Host-specific generated files:

```text
~/.config/hypr/nix/monitors.lua
~/.config/hypr/nix/input.lua
~/.config/hypr/nix/plugins.lua
```

Changes require Home Manager or system rebuild; config is no longer linked directly to mutable checkout.

## Per-host applications

Applications are listed by Nixpkgs attribute name:

```text
hosts/<host>/apps.txt
```

Example:

```text
firefox
kdePackages.kcalc
libreoffice
```

Rules:

- one attribute per line
- blank lines ignored
- lines beginning with `#` ignored
- nested attributes use dots
- unknown attributes fail evaluation
- packages unavailable on host platform are skipped with warning

Interactive management:

```bash
nos-install
nos-install obsidian
nos-remove
```

Both commands read `HOST_NAME` and edit only current host `apps.txt`, then run standalone Home Manager refresh.

For deterministic review, edit file directly and run:

```bash
nos-build
```

## Local environment and secrets

`.env` is ignored by Git. Example:

```bash
export HOST_NAME=legion
export NPM_TOKEN=replace-me
export WINDOWS_USERNAME=Docker
export WINDOWS_PASSWORD=replace-me
```

Behavior:

- helper host selection parses only `HOST_NAME`
- Fish does not source `.env` wholesale
- Windows scripts source `.env` when reading VM credentials
- `.env` should remain mode `0600`

```bash
chmod 600 .env
```

Do not commit:

- `.env`
- Windows password
- NPM token
- bootstrap password hash
- private SSH keys
- local CA private key

1Password SSH module expects agent socket:

```text
~/.1password/agent.sock
```

Enable SSH agent integration inside 1Password application.

## Helper commands

Helpers are installed by Home Manager when `flakeDirectory` is non-null.

### `nos-build`

Formats Nix files, resolves current host from `.env`, and runs:

```bash
sudo nixos-rebuild switch --flake path:$NOS_DIR#$HOST_NAME
```

Supports local-store-only retry:

```bash
nos-build --offline
```

### `nos-refresh`

Formats Nix files and applies standalone Home Manager output:

```bash
home-manager switch --flake path:$NOS_DIR#$USER@$HOST_NAME
```

Use for home-only iteration. System rebuild remains canonical deployment.

### `nos-update`

Runs `nix flake update`, then system rebuild. It does not stage changes in Git.

Review `flake.lock` and build result before committing. Hyprland scroll-overview source is pinned to commit matching expected Hyprland API; Nixpkgs updates can require plugin pin update.

### `nos-install` / `nos-remove`

Fuzzy package search and per-host application list management.

### `nos-new-host`

Creates new host from `_template`, generates hardware config, and preserves existing hosts.

```bash
nos-new-host
nos-new-host --root /mnt
```

### Font helpers

```bash
nos-fonts
nos-mono-fonts
```

List all font families or monospaced families visible through Fontconfig.

## Validation, updates, and rollback

### Format

```bash
nix fmt
# Check without modifying:
nixfmt --check $(find . -name '*.nix' -not -path './.git/*')
```

### Evaluate all outputs

```bash
nix flake check --no-build path:.
```

### Build current host

```bash
nix build --no-link path:.#nixosConfigurations.$HOST_NAME.config.system.build.toplevel
```

### Build standalone home

```bash
nix build --no-link "path:.#homeConfigurations.$USER@$HOST_NAME.activationPackage"
```

### Apply

```bash
nos-build
```

### Update

```bash
nos-update
```

Review:

```bash
git diff -- flake.lock
nix flake check --no-build path:.
```

### Rollback running system

Immediate rollback to previous generation:

```bash
sudo nixos-rebuild switch --rollback
```

Or select older generation in systemd-boot/GRUB menu.

List generations:

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
home-manager generations
```

Because Home Manager is integrated, system generation rollback also restores corresponding managed home generation through NixOS activation.

### Garbage collection

Configured automatic Nix GC runs weekly and deletes generations older than ten days. Before risky migration, keep external backup; old generations are not permanent backups.

## Troubleshooting

### `HOST_NAME missing`

Create local `.env` in repository root:

```bash
printf 'export HOST_NAME=%s\n' '<host>' > .env
chmod 600 .env
```

Confirm output exists:

```bash
nix flake show path:.
```

### New host not visible with `.#...`

Git flakes omit untracked files. Use path flake:

```bash
nix flake show path:.
```

Or add host files to Git. Helpers always use `path:` and do not require staging.

### Home Manager file collision

Move conflicting file aside, then rebuild:

```bash
mv ~/.config/<path> ~/.config/<path>.backup
nos-build
```

Inspect exact collision first; do not delete mutable application data blindly.

### Hyprland starts with wrong display layout

```bash
hyprctl monitors all
```

Update `host.monitors` output names, modes, positions, scales, and workspace assignments. Empty list enables automatic output setup.

### Trackpad gestures do not work

```bash
hyprctl devices
```

Set exact `trackpadName`, then rebuild.

### NVIDIA fails to start

Check:

```bash
journalctl -b -k | grep -iE 'nvidia|nouveau|drm'
nvidia-smi
```

Verify:

- GPU supports selected open/proprietary kernel module
- driver package supports GPU generation
- PRIME bus IDs use decimal NixOS format
- integrated GPU module matches hardware
- firmware/BIOS graphics mode matches configuration

### Suspend fails or resumes immediately

```bash
cat /sys/power/mem_sleep
journalctl -b -u systemd-suspend.service
```

Disable `deepSleep` if firmware does not expose reliable `deep`. Disable `thermald` on non-Intel or unsupported hardware.

### Portals or screen sharing fail

```bash
systemctl --user status xdg-desktop-portal.service
systemctl --user status xdg-desktop-portal-hyprland.service
journalctl --user -b -u xdg-desktop-portal.service
```

Restart user portals after session/environment changes:

```bash
systemctl --user restart xdg-desktop-portal.service
```

Ensure session started through UWSM so portal environment contains correct Wayland and desktop variables.

### DMS themes are missing

```bash
systemctl --user status dms.service
journalctl --user -b -u dms.service
dms ipc call theme getMode
```

DMS must be running before Matugen user templates can be regenerated.

### Intel host evaluation fails after local edits

Intel module must receive `pkgs` in inner NixOS module function. Preserve structure in `modules/system/intel.nix` when editing module wrappers.

### Build ignores local changes

Use `path:.` or helper commands. Plain `.#host` on Git repository can exclude untracked files.

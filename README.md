# NixOS configuration

Multi-host NixOS configuration for x86_64 workstations. It manages both system settings and user environment through Home Manager.

## Desktop stack

- Hyprland with UWSM and swappable desktop-shell modules
- Shared Stylix theming for GTK, Qt, Kitty, Neovim, Firefox, and CLI tools
- Kitty with Fish and Starship
- Firefox, Neovim, Yazi, btop, LazyDocker, GIMP, and LibreOffice
- XDG portals, screen sharing, clipboard, screenshots, and Polkit support
- Host-agnostic formatting, static-analysis, shell, NixOS, and Home Manager checks
- Optional graphics, audio, Bluetooth, Docker, Windows VM, 1Password, printing, Steam, and laptop modules

## Before using it

- Supports `x86_64-linux` with NixOS and Home Manager `26.05`.
- Each machine needs its own directory under `hosts/` with generated `hardware.nix`.
- UEFI uses systemd-boot; BIOS uses GRUB.
- Repository defaults to `/home/<user>/NixOS`.
- `.env` selects current machine through `HOST_NAME`.

No graphical login manager is enabled. Log in through TTY and start Hyprland with:

```bash
startw
```

## Repository structure

```text
hosts/
├── _template/          template used for new machines
└── <hostname>/
    ├── host.nix        machine and user settings
    ├── hardware.nix    generated hardware configuration
    └── apps.nix        applications installed for this host

modules/
├── home/               Home Manager modules
└── system/             NixOS modules
```

Each host exports:

```text
nixosConfigurations.<hostname>
homeConfigurations.<username>@<hostname>
```

View available hosts:

```bash
nix flake show .
```

## Fresh NixOS installation

Follow official NixOS installation guide until target filesystems are mounted under `/mnt`. This README only covers using this repository afterward.

### 1. Clone repository

From installer environment:

```bash
nix shell nixpkgs#git nixpkgs#mkpasswd nixpkgs#fzf
git clone https://github.com/ConRaddest/NixOS.git NixOS
cd NixOS
```

### 2. Create host configuration

```bash
./modules/system/scripts/nos-new-host.sh --root /mnt
```

Wizard asks for:

- hostname and username
- locale, timezone, and keyboard layout from searchable lists
- login password
- UEFI or BIOS boot mode
- graphics hardware
- optional services and laptop features
- final repository path on installed system

Searchable choices open in fzf: type to filter, use arrow keys to move, and press Enter to select.

It creates:

```text
hosts/<hostname>/host.nix
hosts/<hostname>/hardware.nix
hosts/<hostname>/apps.nix
```

For normal installation, use `/home/<username>/NixOS` as target repository path.

### 3. Review generated files

Check `hosts/<hostname>/hardware.nix` contains correct:

- filesystems and UUIDs
- swap device
- CPU microcode
- host platform

Check `hosts/<hostname>/host.nix` contains correct:

- username and home path
- boot mode
- graphics module
- enabled optional modules
- state version

For NVIDIA PRIME systems, confirm GPU bus IDs. `lspci` reports hexadecimal values while NixOS bus IDs use decimal:

```text
01:00.0 -> PCI:1:0:0
0a:00.0 -> PCI:10:0:0
```

### 4. Copy repository into installed system

If repository is not already under `/mnt/home/<username>/NixOS`:

```bash
sudo mkdir -p /mnt/home/<username>
sudo cp -a . /mnt/home/<username>/NixOS
cd /mnt/home/<username>/NixOS
```

### 5. Install configuration

```bash
sudo nixos-install --flake ".#<hostname>"
```

Home Manager is included automatically; no separate Home Manager installation is needed.

Set repository ownership after installation:

```bash
sudo nixos-enter --root /mnt -c 'chown -R <username>:users /home/<username>/NixOS'
```

### 6. Local host selection

Host wizard creates `.env` in repository root when file does not already exist:

```bash
export HOST_NAME=<hostname>
```

After reboot, log in and run:

```bash
startw
```

### 7. Remove temporary password hash

Wizard stores initial password hash in `host.nix`. After first successful login:

1. Run `passwd`.
2. Set `initialHashedPassword = null;` in host file.
3. Rebuild with `nos-build`.

Do not commit initial password hash.

## Existing NixOS installation

### 1. Back up current configuration

Keep copy of `/etc/nixos` and important files currently managed manually under home directory.

### 2. Clone repository

```bash
git clone https://github.com/ConRaddest/NixOS.git ~/NixOS
cd ~/NixOS
nix shell nixpkgs#mkpasswd nixpkgs#fzf
```

### 3. Create host

```bash
./modules/system/scripts/nos-new-host.sh
```

Important choices:

- enter existing `system.stateVersion`, not current NixOS release
- enter current username
- use current boot mode
- enable only hardware/services present on machine

After wizard finishes, set:

```nix
initialHashedPassword = null;
```

Existing password remains unchanged.

### 4. Compare hardware configuration

Compare generated hardware file with existing one.

Manually preserve any custom settings in hardware.nix.

### 5. Confirm local host

Host wizard creates `.env` automatically if missing, confirm its `HOST_NAME` matches machine before rebuilding.

### 6. Review Home Manager changes

Home Manager will begin managing files under `~/.config`, `~/.local/share`, `~/.mozilla`, `~/.pi`, and related paths.

### 7. Apply configuration

Safer first activation:

```bash
cd ~/NixOS
sudo nixos-rebuild boot --flake .#<hostname>
sudo reboot
```

Immediate activation:

```bash
cd ~/NixOS
sudo nixos-rebuild switch --flake .#<hostname>
```

After reboot, log in through TTY and run `startw`.

## Host settings

Main settings live in `hosts/<hostname>/host.nix`.

### Identity

```nix
username = "alice";
fullName = "Alice Butters";
homeDirectory = "/home/alice";
flakeDirectory = "/home/alice/NixOS";
stateVersion = "26.05";
```

### Boot

```nix
boot = {
  mode = "uefi"; # or "bios"
  device = null;  # BIOS example: "/dev/sda"
};
```

### Hardware behavior

```nix
hardware = {
  deepSleep = false;
  thermald = false;
  nvidiaOpen = false;
  nvidiaPrime = null;
};
```

- enable `deepSleep` only if `/sys/power/mem_sleep` supports `deep`
- enable `thermald` only on supported Intel hardware
- set `nvidiaOpen` according to GPU generation
- use `nvidiaPrime` only for hybrid NVIDIA systems

On hosts importing the battery module, Hyprland owns power-key and lid-switch handling while logind ignores those events. Pressing the power key or closing the lid suspends the machine, including on external power and while docked. This behavior requires the Hyprland session to be running.

### Additional mounts

Declare host-specific filesystems without editing generated `hardware.nix`:

```nix
mounts = [
  {
    mountPoint = "/home/alice/SSD";
    device = "/dev/disk/by-uuid/<uuid>";
    fsType = "ext4";
    options = [ "nofail" ];
  }
];
```

Mount points must be absolute. Use stable filesystem UUIDs rather than `/dev/sdX` names.

### Desktop shell

DankMaterialShell provides the desktop shell, launcher, process view, media controls, and Hyprland integration.

### Monitors

Empty list uses Hyprland automatic output handling:

```nix
monitors = [ ];
```

Example fixed layout:

```nix
monitors = [
  {
    output = "eDP-1";
    mode = "1920x1080@60";
    position = "0x0";
    scale = 1;
    workspaces = [ 1 2 3 ];
  }
];
```

Find output names and modes:

```bash
hyprctl monitors all
```

### Trackpad

Find device name:

```bash
hyprctl devices
```

Then set Home Manager host options:

```nix
nos = {
  trackpad = true;
  trackpadName = "device-name";
};
```

### Other host values

Host file also contains:

- Git name and email
- locale, timezone, and keyboard layout
- local `/etc/hosts` aliases
- Firefox profile path, such as `"default"` for new hosts or an existing profile directory such as `"td4m60gg.default"`
- optional Firefox development certificate path
- GDU CPU limit
- Windows VM memory, CPU, disk, and timezone

## Optional modules

Wizard keeps related system and home modules aligned:

| Feature    | System                 | Home                     |
| ---------- | ---------------------- | ------------------------ |
| Audio      | PipeWire               | audio controls           |
| Bluetooth  | bluetoothd             | Bluetui                  |
| Battery    | power profiles         | brightness controls      |
| Docker     | Docker daemon          | LazyDocker               |
| Windows VM | Docker/KVM/TUN         | VM launchers and FreeRDP |
| 1Password  | application and policy | SSH agent config         |
| Printing   | CUPS                   | none                     |
| Steam      | Steam support          | Steam launcher           |

When enabling modules manually, add both sides where applicable.

## Per-host applications

Applications are stored in:

```text
hosts/<hostname>/apps.nix
```

Set `nos.apps` to a list of Nixpkgs package attribute strings:

```nix
{ ... }:

{
  nos.apps = [
    "firefox"
    "libreoffice"
    "kdePackages.kcalc"
  ];
}
```

Manage interactively:

```bash
nos-install
nos-remove
```

Commands edit only host selected by `HOST_NAME`.

## Local `.env`

Example:

```bash
export HOST_NAME=legion
export NPM_TOKEN=replace-me
export WINDOWS_USERNAME=Docker
export WINDOWS_PASSWORD=replace-me
```

Notes:

- `nos-new-host` creates `.env` with new hostname when file is missing.
- `.env` is ignored by Git
- helper commands read `HOST_NAME`
- every interactive Fish terminal loads all exported values from `.env`
- Windows scripts also read Windows credentials directly from `.env`

## Theming

`homeModules.theme` imports Stylix and applies shared theme options, fonts, cursor, wallpaper, and application targets. Theme data uses native directories under `themes/<name>/`, with `colors.toml` as source of truth and wallpapers under `backgrounds/`.

The engine resolves canonical colors, adapts them to Base16 for Stylix, and exposes the complete palette through `config.nos.theme.colors`. Custom Fastfetch, GDU, Hyprland Lua, Kitty, LazyDocker, Neovim, shell, Starship, and Yazi adapters consume the same colors. Optional `hyprland.lua` files apply after the generated Hyprland palette.

Select theme and wallpaper in each host definition:

```nix
theme = {
  name = "tokyo-night";
  wallpaper = "backgrounds/1-sunset-lake.png";
};
```

To add a theme, create its directory in `themes/`, provide `colors.toml` and bundled wallpapers, select it, then rebuild:

```bash
nos-build
```

## Validation and CI

Run every local check:

```bash
nix flake check
```

Show complete logs when a check fails:

```bash
nix flake check -L
```

Evaluate without building:

```bash
nix flake check --no-build
```

Checks cover Nix formatting, Deadnix, Statix, ShellCheck, every exported NixOS configuration, and every exported Home Manager configuration. Host checks are generated from flake outputs, so newly exported hosts are included automatically. `.github/workflows/check.yml` runs the same suite for pushes to `main` and pull requests.

## Common commands

### Build and apply system plus Home Manager

```bash
nos-build
```

### Apply Home Manager only

```bash
nos-refresh
```

Management commands reject untracked Nix files, format only changed Nix files, build before activation, and never stage repository changes. Failed refreshes, package edits, and input updates restore files to their pre-command state. System builds create a persistent NixOS generation before activation and require sudo authentication.

### Update flake inputs and rebuild

```bash
nos-update
```

### Add another host

```bash
nos-new-host
```

### List outputs

```bash
nix flake show .
```

`nos-new-host` marks generated host files with `git add -N`, making them visible to Git-backed flake evaluation without staging their contents. Ignored `.env` remains outside flake source and Nix store.

## Windows VM

Windows module requires Docker and working `/dev/kvm`.

Setup:

```bash
windows-install
```

Start:

```bash
windows-vm-start
```

Stop:

```bash
windows-vm-stop
```

VM files are kept together under:

```text
~/VMs/windows/storage   virtual disk
~/VMs/windows/shared    folder mounted into Windows as /shared
```

Web installer is available at `http://localhost:8006` while container runs.

Uninstall command permanently removes VM data after confirmation:

```bash
windows-uninstall
```

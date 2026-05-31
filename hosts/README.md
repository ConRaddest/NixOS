# Hosts

Each machine gets its own directory under `hosts/`.

This repo uses the dendritic `flake-parts` + `import-tree` pattern: host files are imported automatically by `flake.nix`, and each host exports its own outputs from `hosts/<hostname>/default.nix`.

To add a new machine:

1. Create `hosts/<hostname>/default.nix`.
2. Create `hosts/<hostname>/hardware.nix` that exports `flake.systemModules.<hostname>Hardware`.
3. In `hosts/<hostname>/default.nix`, define that host's local settings, compose modules via `self.systemModules.*` / `self.lib.homeModules.*`, and export:
   - `flake.systemModules.<hostname>Configuration`
   - `flake.nixosConfigurations.<hostname>`
   - optionally `flake.homeConfigurations.<user>`

Host-specific values such as username, full name, home directory, system architecture, and state version intentionally live in the host file rather than in a central settings module.

Path model:

- `self` points at the immutable flake source in the Nix store.
- `config/` contains static resources installed by Home Manager.
- `wallpapers/` contains static wallpaper files.
- `~/.local/state/nos/` contains mutable runtime state, such as the current wallpaper symlink.

# Architecture

## Configuration layers

- `hosts/` selects identity, hardware, features, monitors, theme, and applications.
- `modules/system/` owns NixOS services, hardware, security, and privileged policy.
- `modules/home/` owns Home Manager programs and user services.
- `modules/home/terminal.nix` owns Fish and terminal-shell behavior.
- `modules/home/bin.nix` packages NOS commands. It does not configure terminal or desktop shells.
- Future desktop shell belongs under `modules/home/quickshell/` and runs as one supervised process.

## Runtime roots

NOS commands distinguish immutable program code from mutable configuration:

- `NOS_RUNTIME_DIR` points at packaged scripts under Nix store. Commands source helpers only from this directory.
- `NOS_DIR` points at mutable configuration checkout, normally `~/NixOS`. Commands use it only to read or edit repository data.

Mixing these roots can run entry script and helper from different revisions. Contract tests reject helper imports through `$NOS_DIR/bin`.

## Ownership

Every interface must have one owner. Future desktop-shell work must select one notification server, status-notifier host, wallpaper renderer, lock screen, and Polkit agent. DMS remains owner until replacement shell is ready.

## Mutable operations

Commands that mutate or activate configuration share one non-blocking per-user lock. Nested operations inherit lock ownership, allowing flows such as `nos install` calling `nos refresh` without deadlock. Concurrent top-level operations fail rather than race.

Build commands retain transaction rollback. Future background execution should preserve same lock and transaction contract through systemd user jobs.

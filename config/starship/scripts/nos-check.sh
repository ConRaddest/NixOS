#!/usr/bin/env bash
set -euo pipefail

resolve_config_dir() {
    if [[ -n "${OS_CONFIG_DIR:-}" ]]; then
        printf '%s\n' "$OS_CONFIG_DIR"
        return 0
    fi

    if git_root="$(git rev-parse --show-toplevel 2>/dev/null)" && [[ -f "$git_root/flake.nix" ]]; then
        printf '%s\n' "$git_root"
        return 0
    fi

    echo "OS_CONFIG_DIR is not set and the current directory is not inside the config repo." >&2
    echo "Run this command from inside the repo or export OS_CONFIG_DIR=/path/to/your/checkout." >&2
    return 1
}

OS_CONFIG_DIR="$(resolve_config_dir)"

printf '\033[1;36mChecking integrity of system configuration...\033[0m\n\n'
git -C "$OS_CONFIG_DIR" add .
sudo nixos-rebuild dry-run --flake "$OS_CONFIG_DIR#$HOSTNAME"

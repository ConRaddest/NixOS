#!/usr/bin/env bash
set -euo pipefail

: "${OS_CONFIG_DIR:?OS_CONFIG_DIR is not set}"

printf '\033[1;36mChecking integrity of system configuration...\033[0m\n\n'
sudo nixos-rebuild dry-run --flake "$OS_CONFIG_DIR#$HOSTNAME"

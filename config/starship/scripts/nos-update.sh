#!/usr/bin/env bash
set -euo pipefail

: "${OS_CONFIG_DIR:?OS_CONFIG_DIR is not set}"

printf '\033[1;36mUpdating system to latest packages...\033[0m\n\n'
git -C "$OS_CONFIG_DIR" add .
nix flake update --flake "$OS_CONFIG_DIR"
git -C "$OS_CONFIG_DIR" add flake.lock
sudo nixos-rebuild switch --flake "$OS_CONFIG_DIR#$HOSTNAME"

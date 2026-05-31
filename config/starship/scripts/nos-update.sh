#!/usr/bin/env bash
set -euo pipefail

printf '\033[1;36mUpdating system to latest packages...\033[0m\n\n'
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt
git -C "$NOS_DIR" add .
nix flake update --flake "$NOS_DIR"
git -C "$NOS_DIR" add flake.lock
sudo nixos-rebuild switch --flake "$NOS_DIR#$HOSTNAME"

#!/usr/bin/env bash
set -euo pipefail

printf '\033[1;36mBuilding and switching system configuration...\033[0m\n\n'
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt
git -C "$NOS_DIR" add .
sudo nixos-rebuild switch --flake "$NOS_DIR#$HOSTNAME"

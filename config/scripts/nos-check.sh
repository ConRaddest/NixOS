#!/usr/bin/env bash
set -euo pipefail

printf '\033[1;36mChecking integrity of system configuration...\033[0m\n\n'
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt
git -C "$NOS_DIR" add .
sudo nixos-rebuild dry-run --flake "$NOS_DIR#$HOSTNAME"

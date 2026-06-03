#!/usr/bin/env bash
# Validates the flake without switching: formats Nix files, stages them,
# then runs nixos-rebuild dry-run to check the build would succeed.
set -euo pipefail

printf '\033[1;36mChecking integrity of system configuration...\033[0m\n\n'

# Format and stage so the dry-run evaluates the same source that would be built.
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt
git -C "$NOS_DIR" add .
sudo nixos-rebuild dry-run --flake "$NOS_DIR#$HOSTNAME"

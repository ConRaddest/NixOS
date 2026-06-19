#!/usr/bin/env bash
# Validates the flake without switching: formats Nix files, stages them,
# then runs nixos-rebuild dry-run to check the build would succeed.
set -euo pipefail

# shellcheck source=scripts/system/progress.sh
source "$NOS_DIR/scripts/system/progress.sh"

printf '\033[1;36mChecking integrity of system configuration...\033[0m\n'

# Format and stage so the dry-run evaluates the same source that would be built.
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} +
git -C "$NOS_DIR" add .

nos_stage "dry-run nixos"
sudo nixos-rebuild dry-run --flake "$NOS_DIR#$HOSTNAME"

nos_done

#!/usr/bin/env bash
# Validates the flake without switching: formats Nix files, stages them,
# then runs nixos-rebuild dry-run to check the build would succeed.
set -euo pipefail

# shellcheck source=scripts/system/progress.sh
source "$NOS_DIR/scripts/system/progress.sh"

# Format and stage so the dry-run evaluates the same source that would be built.
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} +
git -C "$NOS_DIR" add .

nos_stage "checking configuration in $NOS_DIR..."
nos_run sudo nixos-rebuild dry-run --option warn-dirty false --flake "$NOS_DIR#$HOSTNAME"

nos_done

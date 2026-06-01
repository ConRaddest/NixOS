#!/usr/bin/env bash
set -euo pipefail

offline=""
if [[ "${1:-}" == "--offline" ]]; then
  offline="--option substitute false"
fi

printf '\033[1;36mSyncing home manager configuration...\033[0m\n\n'
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt
git -C "$NOS_DIR" add .
home-manager switch $offline --flake "$NOS_DIR#$USER"

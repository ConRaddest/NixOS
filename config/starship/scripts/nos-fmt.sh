#!/usr/bin/env bash
set -euo pipefail

printf '\033[1;36mFormatting Nix files...\033[0m\n\n'
find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" | xargs -r nixfmt

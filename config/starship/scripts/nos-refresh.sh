#!/usr/bin/env bash
set -euo pipefail

: "${OS_CONFIG_DIR:?OS_CONFIG_DIR is not set}"

printf '\033[1;36mSyncing home manager configuration...\033[0m\n\n'
home-manager switch --flake "$OS_CONFIG_DIR#$USER"

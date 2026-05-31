#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ───────────────────────────────────────────────────────────────────
: "${OS_CONFIG_DIR:?OS_CONFIG_DIR is not set}"

wallpaper="${1:-}"

if [[ -z "$wallpaper" ]]; then
    echo "usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "wallpaper not found: $wallpaper" >&2
    exit 1
fi

# Resolve symlinks and keep paths inside the repo relative to configDir so the
# repo can move without needing to patch generated absolute paths later.
wallpaper="$(readlink -f "$wallpaper")"
if [[ "$wallpaper" == "$OS_CONFIG_DIR"/* ]]; then
    nix_wallpaper='${configDir}'"${wallpaper#"$OS_CONFIG_DIR"}"
else
    nix_wallpaper="$wallpaper"
fi

# ─── Patch NixOS config ──────────────────────────────────────────────────────
# Replace the path in the let-binding line of hyprpaper.nix.
python3 - "$OS_CONFIG_DIR/modules/hyprpaper.nix" "$nix_wallpaper" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
wallpaper = sys.argv[2]
text = path.read_text()
text = re.sub(r'(?m)^(  wallpaper = ")[^"]*(";)$', r'\1' + wallpaper + r'\2', text, count=1)
path.write_text(text)
PY

# ─── Rebuild ─────────────────────────────────────────────────────────────────
# Run nos-refresh in a floating terminal (nixos-refresh window rule makes it float).
kitty --class nixos-refresh --title nixos-refresh -e bash -lic \
    "nos-refresh; echo; read -rp 'Press Enter to close...'" &
disown

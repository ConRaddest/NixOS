#!/usr/bin/env bash
# Format and rebuild the selected NixOS host.
set -uo pipefail

# shellcheck source=modules/home/shell/scripts/nos-ui.sh
source "$NOS_DIR/modules/home/shell/scripts/nos-ui.sh"

# ╭──────────────────────────────────────────────────────────╮
# │ Options                                                  │
# ╰──────────────────────────────────────────────────────────╯

nix_opts=(--option warn-dirty false)
if [[ "${1:-}" == "--offline" ]]; then
  nix_opts+=(--option substitute false)
fi

# ╭──────────────────────────────────────────────────────────╮
# │ Rebuild                                                  │
# ╰──────────────────────────────────────────────────────────╯

run_build() {
  local host_name
  host_name=$(nos_host_name)

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_stage "Building NixOS Configuration" \
    && nos_run sudo nixos-rebuild switch "${nix_opts[@]}" --flake "$NOS_DIR#$host_name" \
    && nos_done "NixOS configuration applied successfully."
}

# ╭──────────────────────────────────────────────────────────╮
# │ Main                                                     │
# ╰──────────────────────────────────────────────────────────╯

while true; do
  if run_build; then
    nos_repeat_prompt
    read -r -n 1 answer
    printf '\n'
    [[ "$answer" =~ ^[yY]$ ]] || exit 0
  else
    nos_fail "NixOS rebuild failed."
    nos_retry_prompt
    read -r -n 1 answer
    printf '\n'
    case "$answer" in
      ''|y|Y) ;;
      *) exit 1 ;;
    esac
  fi
done

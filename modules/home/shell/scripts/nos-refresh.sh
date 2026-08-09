#!/usr/bin/env bash
# Format and apply the selected standalone Home Manager profile.
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
# │ Refresh                                                  │
# ╰──────────────────────────────────────────────────────────╯

run_refresh() {
  local host_name profile
  host_name=$(nos_host_name)
  profile="$USER@$host_name"

  find "$NOS_DIR" -name "*.nix" -not -path "*/.git/*" -exec nixfmt {} + \
    && nos_stage "Applying Home Manager Configuration" \
    && nos_run home-manager switch "${nix_opts[@]}" --flake "$NOS_DIR#$profile" \
    && nos_done "Home Manager configuration applied successfully."
}

# ╭──────────────────────────────────────────────────────────╮
# │ Main                                                     │
# ╰──────────────────────────────────────────────────────────╯

while true; do
  if run_refresh; then
    nos_repeat_prompt
    read -r -n 1 answer
    printf '\n\n'
    [[ "$answer" =~ ^[yY]$ ]] || exit 0
  else
    nos_fail "Home Manager refresh failed."
    nos_retry_prompt
    read -r -n 1 answer
    printf '\n\n'
    case "$answer" in
      ''|y|Y) ;;
      *) exit 1 ;;
    esac
  fi
done

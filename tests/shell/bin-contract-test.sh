#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
module="$repo_root/modules/home/bin.nix"

commands=(
  build
  update
  refresh
  install
  remove
  webapp-install
  iso-install
  iso-boot
  new-host
)

for command in "${commands[@]}"; do
  script="nos-$command.sh"
  [[ -f "$repo_root/bin/$script" ]] || {
    printf 'Missing command script: %s\n' "$script" >&2
    exit 1
  }
  grep -Fq "script = \"$script\";" "$module" || {
    printf 'Command is absent from bin module registry: %s\n' "$command" >&2
    exit 1
  }
done

if grep -REn 'source .*\$\{?NOS_DIR.*bin/nos-(ui|apps)\.sh' "$repo_root/bin"; then
  printf 'Packaged scripts must not source helpers from mutable NOS_DIR.\n' >&2
  exit 1
fi

for script in nos-apps.sh nos-build.sh nos-install.sh nos-new-host.sh nos-refresh.sh nos-remove.sh nos-update.sh nos-webapp-install.sh; do
  grep -Fq 'NOS_RUNTIME_DIR' "$repo_root/bin/$script" || {
    printf 'Script does not use immutable runtime root: %s\n' "$script" >&2
    exit 1
  }
done

# shellcheck disable=SC2016 # Match literal source assignment.
grep -Fq 'template_dir="$repo_dir/hosts/.template"' "$repo_root/bin/nos-new-host.sh" || {
  printf 'Host generator does not target hosts/.template.\n' >&2
  exit 1
}

printf 'bin contracts: ok\n'

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
runtime_dir=$(mktemp -d)
ready="$runtime_dir/ready"
trap 'rm -rf -- "$runtime_dir"' EXIT

XDG_RUNTIME_DIR="$runtime_dir" bash -c '
  set -euo pipefail
  source "$1/bin/nos-ui.sh"
  nos_operation_lock
  touch "$2"
  sleep 1
' _ "$repo_root" "$ready" &
holder=$!

for _ in {1..100}; do
  [[ -e "$ready" ]] && break
  sleep 0.01
done
[[ -e "$ready" ]] || {
  printf 'Lock holder did not start.\n' >&2
  kill "$holder" 2>/dev/null || true
  wait "$holder" 2>/dev/null || true
  exit 1
}

if XDG_RUNTIME_DIR="$runtime_dir" bash -c '
  set -euo pipefail
  source "$1/bin/nos-ui.sh"
  nos_operation_lock
' _ "$repo_root" 2>/dev/null; then
  printf 'Concurrent operation unexpectedly acquired lock.\n' >&2
  kill "$holder" 2>/dev/null || true
  wait "$holder" 2>/dev/null || true
  exit 1
fi

wait "$holder"

XDG_RUNTIME_DIR="$runtime_dir" bash -c '
  set -euo pipefail
  source "$1/bin/nos-ui.sh"
  nos_operation_lock
' _ "$repo_root"

printf 'operation lock: ok\n'

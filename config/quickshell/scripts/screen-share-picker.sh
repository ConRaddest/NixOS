#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
request_dir="$runtime_dir/quickshell-screen-share-picker"
mkdir -p "$request_dir"

# Kill stale instances and clean up leftover state.
script_path="$(readlink -f "$0")"
for pid in $(pgrep -f "$script_path" || true); do
  if [[ "$pid" != "$$" ]]; then
    kill "$pid" 2>/dev/null || true
  fi
done
rm -f "$request_dir"/*.result "$request_dir"/*.items 2>/dev/null || true
rm -rf "$request_dir"/*-previews 2>/dev/null || true
qs ipc --newest call screenshare close >/dev/null 2>&1 || true

id="$$-$(date +%s%N)"
source_file="$request_dir/$id.items"
result_file="$request_dir/$id.result"
preview_dir="$request_dir/$id-previews"
log_file="$HOME/.cache/screen-share-picker.log"
mkdir -p "$preview_dir" "$(dirname "$log_file")"
rm -f "$source_file" "$result_file"

monitor_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"

# Capture all monitor previews in parallel, then collect results in order.
# A short delay lets the compositor flush GPU-rendered content so screencopy
# doesn't return black frames for hardware-accelerated windows.
sleep 0.15

declare -A preview_pids
declare -A preview_paths
declare -a monitor_names
declare -A monitor_labels

while IFS=$'\t' read -r name label; do
  monitor_names+=("$name")
  monitor_labels["$name"]="$label"
  preview="$preview_dir/screen-$name.png"
  preview_paths["$name"]="$preview"
  grim -o "$name" "$preview" >/dev/null 2>&1 &
  preview_pids["$name"]=$!
done < <(printf '%s\n' "$monitor_json" | jq -r '.[] | [.name, ("Screen " + .name)] | @tsv')

# Wait for all captures to finish, then write the items file in order.
for name in "${monitor_names[@]}"; do
  wait "${preview_pids[$name]}" 2>/dev/null || true
  preview="${preview_paths[$name]}"
  [[ -f "$preview" ]] || preview=""
  printf 'screen|%s|%s|%s\n' "$name" "${monitor_labels[$name]}" "$preview" >> "$source_file"
done

if ! command -v qs >/dev/null 2>&1; then
  echo "qs not found" >> "$log_file"
  exit 1
fi

wait_for_qs() {
  for attempt in {1..50}; do
    if qs ipc --newest call screenshare close >> "$log_file" 2>&1; then
      return 0
    fi
    echo "quickshell not ready retry $attempt" >> "$log_file"
    sleep 0.1
  done
  return 1
}

if ! wait_for_qs; then
  echo "quickshell never became ready" >> "$log_file"
  rm -rf "$preview_dir" "$source_file" "$result_file"
  exit 1
fi

for attempt in {1..10}; do
  qs ipc --newest call screenshare close >> "$log_file" 2>&1 || true
  sleep 0.05
  if qs ipc --newest call screenshare open "$result_file" "$source_file" >> "$log_file" 2>&1; then
    break
  fi
  echo "screen share picker open retry $attempt" >> "$log_file"
  sleep 0.1
done

# Poll the result file. The picker writes to it on selection or cancel.
# No need to check hyprctl — if the user closes the window without selecting,
# the QML cancel() handler writes "cancel" to the result file.
for _ in {1..600}; do
  [[ -s "$result_file" ]] && break
  sleep 0.1
done

if [[ ! -s "$result_file" ]]; then
  echo "screen share picker timed out" >> "$log_file"
  rm -rf "$preview_dir" "$source_file" "$result_file"
  exit 1
fi

selection="$(cat "$result_file")"
rm -f "$source_file" "$result_file"
rm -rf "$preview_dir"

case "$selection" in
  cancel|'')
    exit 1
    ;;
  region:*)
    # Delay before region capture so compositor flushes GPU content.
    sleep 0.1
    geometry="$(slurp -f '%o@%x,%y,%w,%h' 2>/dev/null || true)"
    [[ -n "$geometry" ]] || exit 1

    # slurp returns global compositor coordinates; the portal expects
    # output-relative coordinates. Subtract the monitor's origin offset.
    output="${geometry%%@*}"
    coords="${geometry#*@}"
    IFS=',' read -r gx gy w h <<< "$coords"
    mon_offset="$(hyprctl monitors -j | jq -r --arg n "$output" '.[] | select(.name == $n) | "\(.x),\(.y)"')"
    IFS=',' read -r ox oy <<< "$mon_offset"
    printf '[SELECTION]region:%s@%d,%d,%d,%d\n' "$output" $(( gx - ox )) $(( gy - oy )) "$w" "$h"
    ;;
  screen:*)
    printf '[SELECTION]%s\n' "$selection"
    ;;
  *)
    echo "invalid selection: $selection" >> "$log_file"
    exit 1
    ;;
esac

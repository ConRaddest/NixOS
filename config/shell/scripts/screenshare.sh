#!/usr/bin/env bash
set -euo pipefail

# ─── Setup ───────────────────────────────────────────────────────────────────
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
request_dir="$runtime_dir/quickshell-screen-share-picker"
mkdir -p "$request_dir"

# Kill any stale instance of this script and remove its leftover temp files.
script_path="$(readlink -f "$0")"
for pid in $(pgrep -f "$script_path" || true); do
    if [[ "$pid" != "$$" ]]; then
        kill "$pid" 2>/dev/null || true
    fi
done
rm -f "$request_dir"/*.result "$request_dir"/*.items 2>/dev/null || true
rm -rf "$request_dir"/*-previews 2>/dev/null || true
qs ipc --newest call screenshare close >/dev/null 2>&1 || true

# Unique ID for this invocation's temp files.
id="$$-$(date +%s%N)"
source_file="$request_dir/$id.items"
result_file="$request_dir/$id.result"
preview_dir="$request_dir/$id-previews"
log_file="$HOME/.cache/screen-share-picker.log"
mkdir -p "$preview_dir" "$(dirname "$log_file")"
rm -f "$source_file" "$result_file"

# ─── Monitor previews ────────────────────────────────────────────────────────
monitor_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"

# Brief delay so the compositor flushes GPU content before screencopy runs.
# Without this, hardware-accelerated windows may appear as black frames.
sleep 0.15

declare -A preview_pids
declare -A preview_paths
declare -a monitor_names
declare -A monitor_labels

# Launch all grim captures in parallel.
while IFS=$'\t' read -r name label; do
    monitor_names+=("$name")
    monitor_labels["$name"]="$label"
    preview="$preview_dir/screen-$name.png"
    preview_paths["$name"]="$preview"
    grim -o "$name" "$preview" >/dev/null 2>&1 &
    preview_pids["$name"]=$!
done < <(printf '%s\n' "$monitor_json" | jq -r '.[] | [.name, ("Screen " + .name)] | @tsv')

# Wait for captures to finish, then write the items file in monitor order.
for name in "${monitor_names[@]}"; do
    wait "${preview_pids[$name]}" 2>/dev/null || true
    preview="${preview_paths[$name]}"
    [[ -f "$preview" ]] || preview=""
    printf 'screen|%s|%s|%s\n' "$name" "${monitor_labels[$name]}" "$preview" >> "$source_file"
done

# ─── Wait for Quickshell ─────────────────────────────────────────────────────
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

# ─── Open the picker ─────────────────────────────────────────────────────────
# Close any existing instance first, then open with the new files.
for attempt in {1..10}; do
    qs ipc --newest call screenshare close >> "$log_file" 2>&1 || true
    sleep 0.05
    if qs ipc --newest call screenshare open "$result_file" "$source_file" >> "$log_file" 2>&1; then
        break
    fi
    echo "screen share picker open retry $attempt" >> "$log_file"
    sleep 0.1
done

# ─── Poll for result ─────────────────────────────────────────────────────────
# The QML picker writes a result token on selection or cancel.
# 60s timeout (600 × 0.1s) — enough for a user to decide.
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

# ─── Output selection ────────────────────────────────────────────────────────
case "$selection" in
    cancel|'')
        exit 1
        ;;

    region:*)
        # Small delay so the compositor flushes GPU content before region capture.
        sleep 0.1
        geometry="$(slurp -f '%o@%x,%y,%w,%h' 2>/dev/null || true)"
        [[ -n "$geometry" ]] || exit 1

        # slurp returns global compositor coordinates; the portal needs
        # output-relative coordinates, so subtract the monitor's origin offset.
        output="${geometry%%@*}"
        coords="${geometry#*@}"
        IFS=',' read -r gx gy w h <<< "$coords"
        mon_offset="$(hyprctl monitors -j | jq -r --arg n "$output" \
            '.[] | select(.name == $n) | "\(.x),\(.y)"')"
        IFS=',' read -r ox oy <<< "$mon_offset"
        printf '[SELECTION]region:%s@%d,%d,%d,%d\n' \
            "$output" $(( gx - ox )) $(( gy - oy )) "$w" "$h"
        ;;

    screen:*)
        printf '[SELECTION]%s\n' "$selection"
        ;;

    *)
        echo "invalid selection: $selection" >> "$log_file"
        exit 1
        ;;
esac

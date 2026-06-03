#!/usr/bin/env bash
# Screen-share source picker — invoked by the xdg-desktop-portal screencasting
# implementation. Presents a Quickshell overlay so the user can select a monitor
# or region, then writes the formatted selection to stdout for the portal.
set -euo pipefail

# ─── Setup ───────────────────────────────────────────────────────────────────
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
request_dir="$runtime_dir/quickshell-screen-share-picker"
mkdir -p "$request_dir"

# Kill any previous instance of this script and remove its leftover temp files.
# Only one picker should be active at a time.
script_path="$(readlink -f "$0")"
for pid in $(pgrep -f "$script_path" || true); do
    if [[ "$pid" != "$$" ]]; then
        kill "$pid" 2>/dev/null || true
    fi
done
rm -f  "$request_dir"/*.result "$request_dir"/*.items 2>/dev/null || true
rm -rf "$request_dir"/*-previews 2>/dev/null || true
qs ipc --newest call screenshare close >/dev/null 2>&1 || true

# All temp files for this invocation share a unique ID (PID + nanosecond
# timestamp) so concurrent portal requests don't collide.
id="$$-$(date +%s%N)"
source_file="$request_dir/$id.items"    # selectable sources written by this script
result_file="$request_dir/$id.result"   # selection token written by the QML picker
preview_dir="$request_dir/$id-previews"
log_file="$HOME/.cache/screen-share-picker.log"
mkdir -p "$preview_dir" "$(dirname "$log_file")"
rm -f "$source_file" "$result_file"

# ─── Monitor previews ────────────────────────────────────────────────────────
monitor_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"

# Wait for the compositor to flush GPU-rendered content to the framebuffer.
# Without this delay, hardware-accelerated windows often appear as black frames
# in the grim screenshots used as picker thumbnails.
sleep 0.15

declare -A preview_pids
declare -A preview_paths
declare -a monitor_names
declare -A monitor_labels

# Launch all grim captures in parallel to keep startup latency low.
while IFS=$'\t' read -r name label; do
    monitor_names+=("$name")
    monitor_labels["$name"]="$label"
    preview="$preview_dir/screen-$name.png"
    preview_paths["$name"]="$preview"
    grim -o "$name" "$preview" >/dev/null 2>&1 &
    preview_pids["$name"]=$!
done < <(printf '%s\n' "$monitor_json" | jq -r '.[] | [.name, ("Screen " + .name)] | @tsv')

# Wait for each capture, then write the items file in monitor order.
# An empty preview path is written when grim fails; the picker shows no thumbnail.
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

# Retry until the Quickshell IPC socket is accepting connections.
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
# Close any lingering instance first, then retry opening in case Quickshell
# is still processing the close when we send the open call.
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
# The QML picker writes a token to result_file on selection or cancel.
# Poll every 100ms for up to 60 seconds before giving up.
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
        # Brief delay so GPU content is flushed before slurp draws its selection overlay.
        sleep 0.1
        geometry="$(slurp -f '%o@%x,%y,%w,%h' 2>/dev/null || true)"
        [[ -n "$geometry" ]] || exit 1

        # slurp returns compositor-global coordinates (origin at the top-left of
        # the combined screen space). The portal expects output-relative coordinates,
        # so subtract the monitor's own origin offset.
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

#!/usr/bin/env bash
# osd.sh <volume|brightness> <up|down|mute>
# Runs the appropriate command then sends the new value to the OSD via IPC.
set -euo pipefail

type="$1"
action="$2"

case "$type" in
  volume)
    case "$action" in
      up)   pamixer -i 5 ;;
      down) pamixer -d 5 ;;
      mute) pamixer -t  ;;
    esac

    muted=$(pamixer --get-mute 2>/dev/null || echo "false")
    value=$(pamixer --get-volume 2>/dev/null || echo "0")

    if [ "$muted" = "true" ]; then icon="󰖁"
    else                           icon="󰕾"
    fi
    ;;

  brightness)
    case "$action" in
      up)   brightnessctl set 5%+ >/dev/null ;;
      down) brightnessctl set 5%- >/dev/null ;;
    esac

    value=$(brightnessctl -m | awk -F, '{gsub(/%/,"",$4); print $4}')
    icon="󰃞"
    ;;
esac

qs ipc call osd trigger "${icon}:${value}"

#!/usr/bin/env bash
# osd.sh <volume|brightness|mic> <up|down|mute>
set -euo pipefail

type="$1"
action="$2"

vol_value() {
  local raw
  raw=$(wpctl get-volume "$1" 2>/dev/null || echo "Volume: 0.00")
  awk '{printf "%d", $2 * 100}' <<< "$raw"
}

vol_muted() {
  wpctl get-volume "$1" 2>/dev/null | grep -q '\[MUTED\]' && echo "true" || echo "false"
}

case "$type" in
  volume)
    case "$action" in
      up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
      down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      mute) wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle ;;
    esac

    muted=$(vol_muted @DEFAULT_AUDIO_SINK@)
    value=$(vol_value @DEFAULT_AUDIO_SINK@)

    if [ "$muted" = "true" ]; then icon="󰖁"; value=0
    else                           icon="󰕾"
    fi
    ;;

  mic)
    case "$action" in
      up)   wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+    || true ;;
      down) wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-    || true ;;
      mute) wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle || true ;;
    esac

    muted=$(vol_muted @DEFAULT_AUDIO_SOURCE@)
    value=$(vol_value @DEFAULT_AUDIO_SOURCE@)

    if [ "$muted" = "true" ]; then icon="󰍭"; value=0
    else                           icon="󰍬"
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

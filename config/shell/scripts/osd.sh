#!/usr/bin/env bash
# osd.sh <volume|brightness|mic> <up|down|mute>
set -euo pipefail

type="$1"
action="$2"

MAX_VOLUME=1.5
VOLUME_STEP=5

wpctl_ids() {
  local start="$1"
  local end="$2"

  wpctl status 2>/dev/null | awk -v start="$start" -v end="$end" '
    index($0, start) { in_section = 1; next }
    in_section && index($0, end) { exit }
    in_section && match($0, /[0-9]+\./) {
      print substr($0, RSTART, RLENGTH - 1)
    }
  '
}

sink_ids() {
  wpctl_ids "Sinks:" "Sources:"
}

source_ids() {
  wpctl_ids "Sources:" "Filters:"
}

for_each_id() {
  local fallback="$1"
  local ids="$2"
  shift 2

  if [ -n "$ids" ]; then
    while IFS= read -r id; do
      [ -n "$id" ] && "$@" "$id" || true
    done <<< "$ids"
  else
    "$@" "$fallback" || true
  fi
}

vol_value() {
  local raw
  raw=$(wpctl get-volume "$1" 2>/dev/null || echo "Volume: 0.00")
  awk '{printf "%d", $2 * 100}' <<< "$raw"
}

vol_value_max() {
  local fallback="$1"
  local ids="$2"
  local max=0 value

  if [ -n "$ids" ]; then
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      value=$(vol_value "$id")
      [ "$value" -gt "$max" ] && max="$value"
    done <<< "$ids"
  else
    max=$(vol_value "$fallback")
  fi

  printf '%s\n' "$max"
}

vol_muted() {
  wpctl get-volume "$1" 2>/dev/null | grep -q '\[MUTED\]' && echo "true" || echo "false"
}

all_muted() {
  local fallback="$1"
  local ids="$2"

  if [ -n "$ids" ]; then
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      [ "$(vol_muted "$id")" != "true" ] && return 1
    done <<< "$ids"
    return 0
  fi

  [ "$(vol_muted "$fallback")" = "true" ]
}

set_volume_id() {
  wpctl set-volume -l "$MAX_VOLUME" "$1" "${VOLUME_STEP}%${volume_delta}"
}

set_mute_id() {
  wpctl set-mute "$1" "$mute_state"
}

case "$type" in
  volume)
    ids=$(sink_ids)

    case "$action" in
      up|down)
        [ "$action" = "up" ] && volume_delta="+" || volume_delta="-"
        for_each_id @DEFAULT_AUDIO_SINK@ "$ids" set_volume_id
        ;;
      mute)
        if all_muted @DEFAULT_AUDIO_SINK@ "$ids"; then mute_state=0
        else                                         mute_state=1
        fi
        for_each_id @DEFAULT_AUDIO_SINK@ "$ids" set_mute_id
        ;;
    esac

    value=$(vol_value_max @DEFAULT_AUDIO_SINK@ "$ids")

    if all_muted @DEFAULT_AUDIO_SINK@ "$ids"; then icon="󰖁"; value=0
    else                                      icon="󰕾"
    fi
    ;;

  mic)
    ids=$(source_ids)

    case "$action" in
      up|down)
        [ "$action" = "up" ] && volume_delta="+" || volume_delta="-"
        for_each_id @DEFAULT_AUDIO_SOURCE@ "$ids" set_volume_id
        ;;
      mute)
        if all_muted @DEFAULT_AUDIO_SOURCE@ "$ids"; then mute_state=0
        else                                           mute_state=1
        fi
        for_each_id @DEFAULT_AUDIO_SOURCE@ "$ids" set_mute_id
        ;;
    esac

    value=$(vol_value_max @DEFAULT_AUDIO_SOURCE@ "$ids")

    if all_muted @DEFAULT_AUDIO_SOURCE@ "$ids"; then icon="󰍭"; value=0
    else                                        icon="󰍬"
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

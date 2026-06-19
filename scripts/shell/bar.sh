#!/usr/bin/env bash
# Emits one pipe-delimited line: RAM_GiB|NET_ICON|BT_ICON|BATTERY_TEXT|VOLUME_ICON
# Called every second by Quickshell. Keep this light: read /proc and /sys
# directly, and throttle slower status probes with a tiny runtime cache.

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/nos-bar"
mkdir -p "$runtime_dir"

now=$(date +%s)

cache_get_or_run() {
  local key="$1" ttl="$2"
  shift 2
  local file="$runtime_dir/$key"
  local stamp=0
  stamp=$(stat -c %Y "$file" 2>/dev/null || printf 0)
  if (( now - stamp < ttl )); then
    cat "$file"
    return
  fi
  "$@" > "$file" 2>/dev/null || true
  cat "$file" 2>/dev/null || true
}

# ─── RAM ─────────────────────────────────────────────────────────────────────
RAM_USAGE=$(awk '
  /^MemTotal:/ { total = $2 }
  /^MemAvailable:/ { available = $2 }
  END { printf "%.1fG", (total - available) / 1048576 }
' /proc/meminfo)

# ─── Network ─────────────────────────────────────────────────────────────────
network_icon() {
  local intf operstate carrier wifi_intf signal
  for path in /sys/class/net/en*; do
    [[ -e "$path" ]] || continue
    intf="${path##*/}"
    operstate=$(cat "$path/operstate" 2>/dev/null || true)
    carrier=$(cat "$path/carrier" 2>/dev/null || true)
    if [[ "$operstate" == "up" ]]; then
      printf '󰈁\n'
      return
    elif [[ "$carrier" == "1" ]]; then
      printf '󰈂\n'
      return
    fi
  done

  for path in /sys/class/net/wl*; do
    [[ -e "$path" ]] || continue
    wifi_intf="${path##*/}"
    if [[ "$(cat "$path/operstate" 2>/dev/null)" == "up" ]]; then
      signal=$(awk -v iface="$wifi_intf" '$1 ~ iface":" { gsub(/\./, "", $3); printf "%d", ($3 / 70) * 100 }' /proc/net/wireless 2>/dev/null)
      : "${signal:=100}"
      if   [[ "$signal" -ge 75 ]]; then printf '󰤨\n'
      elif [[ "$signal" -ge 50 ]]; then printf '󰤥\n'
      elif [[ "$signal" -ge 25 ]]; then printf '󰤢\n'
      elif [[ "$signal" -gt  0 ]]; then printf '󰤟\n'
      else                                  printf '󰤯\n'
      fi
      return
    fi
  done

  printf '󰤮\n'
}
WIFI_ICON=$(network_icon)

# ─── Bluetooth ───────────────────────────────────────────────────────────────
bluetooth_icon() {
  if command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    printf '󰂯\n'
  else
    printf '󰂲\n'
  fi
}
BLUETOOTH_ICON=$(cache_get_or_run bluetooth 5 bluetooth_icon)
: "${BLUETOOTH_ICON:=󰂲}"

# ─── Battery ─────────────────────────────────────────────────────────────────
if [[ -d /sys/class/power_supply/BAT0 ]]; then
  BAT_PCT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || printf 100)
  BAT_STAT=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || printf Unknown)
  BUCKET=$((BAT_PCT / 10))
  [[ "$BUCKET" -gt 10 ]] && BUCKET=10

  if [[ "$BAT_STAT" == "Charging" ]]; then
    case "$BUCKET" in
      0) GLYPH="󰢟" ;; 1) GLYPH="󰢜" ;; 2) GLYPH="󰂆" ;; 3) GLYPH="󰂇" ;; 4) GLYPH="󰂈" ;;
      5) GLYPH="󰢝" ;; 6) GLYPH="󰂉" ;; 7) GLYPH="󰢞" ;; 8) GLYPH="󰂊" ;; 9) GLYPH="󰂋" ;; 10) GLYPH="󰂅" ;;
    esac
  else
    case "$BUCKET" in
      0) GLYPH="󰂎" ;; 1) GLYPH="󰁺" ;; 2) GLYPH="󰁻" ;; 3) GLYPH="󰁼" ;; 4) GLYPH="󰁽" ;;
      5) GLYPH="󰁾" ;; 6) GLYPH="󰁿" ;; 7) GLYPH="󰂀" ;; 8) GLYPH="󰂁" ;; 9) GLYPH="󰂂" ;; 10) GLYPH="󰁹" ;;
    esac
  fi
  BAT_ICON="$GLYPH $BAT_PCT%"
else
  BAT_ICON="󰂅 AC"
fi

# ─── Screen share ────────────────────────────────────────────────────────────
screenshare_status() {
  command -v pw-dump >/dev/null 2>&1 || return
  command -v jq      >/dev/null 2>&1 || return
  pw-dump 2>/dev/null | jq -re '
    any(.[]; .info.props["media.class"] == "Video/Source"
         and .info.state == "running"
         and .info.props["media.role"] != "Camera")
    | if . then "󰹑" else "" end
  ' 2>/dev/null
}
SCREENSHARE=$(cache_get_or_run screenshare 2 screenshare_status)
: "${SCREENSHARE:=}"

# ─── Volume ──────────────────────────────────────────────────────────────────
volume_icon() {
  local raw vol
  raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
  vol=$(awk '{printf "%d", $2 * 100}' <<< "$raw")
  if echo "$raw" | grep -q '\[MUTED\]'; then printf '󰝟\n'
  elif [[ "$vol" -ge 67 ]]; then             printf '󰕾\n'
  elif [[ "$vol" -ge 34 ]]; then             printf '󰖀\n'
  else                                        printf '󰕿\n'
  fi
}
VOL_ICON=$(cache_get_or_run volume 2 volume_icon)
: "${VOL_ICON:=󰕾}"

printf '%s|%s|%s|%s|%s|%s\n' "$RAM_USAGE" "$WIFI_ICON" "$BLUETOOTH_ICON" "$BAT_ICON" "$VOL_ICON" "$SCREENSHARE"

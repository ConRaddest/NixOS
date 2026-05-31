#!/usr/bin/env bash
# Emits one pipe-delimited line: CPU%|RAM_GiB|WIFI_ICON|BLUETOOTH_ICON|BATTERY
# Consumed by the shell root's status process on a 1-second timer.

# ─── CPU ─────────────────────────────────────────────────────────────────────
CPU_RAW=$(top -bn1 | awk '/^%Cpu/ {print $2+$4+$6}')
CPU_USAGE=$(awk -v cpu="$CPU_RAW" 'BEGIN { printf "  %.1f%%", cpu }')

# Fallback: derive usage from idle time if the primary field returned nothing.
if [ -z "$CPU_USAGE" ] || [ "$CPU_USAGE" = "0.0%" ]; then
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
    CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN { printf "%.1f%%", 100 - idle }')
fi

# ─── RAM ─────────────────────────────────────────────────────────────────────
RAM_USAGE=$(free -m | awk '/Mem:/ { printf "  %0.1fG", $3/1024 }')

# ─── Wi-Fi ───────────────────────────────────────────────────────────────────
# Detect the wireless interface name and check if it is up.
WIFI_INTF=$(ip link | awk -F': ' '/wl/ {print $2}' | head -n 1)
[ -z "$WIFI_INTF" ] && WIFI_INTF="wlan0"

WIFI_UP="false"
if [ -f "/sys/class/net/$WIFI_INTF/operstate" ] && \
   [ "$(cat /sys/class/net/$WIFI_INTF/operstate)" = "up" ]; then
    WIFI_UP="true"
fi

if [ "$WIFI_UP" != "true" ]; then
    WIFI_ICON="󰤮"
else
    # Signal strength via NetworkManager; default to 100 if unavailable.
    WIFI_SIGNAL=""
    if command -v nmcli &>/dev/null; then
        WIFI_SIGNAL=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')
    fi
    : "${WIFI_SIGNAL:=100}"

    if   [ "$WIFI_SIGNAL" -ge 75 ]; then WIFI_ICON="󰤨"
    elif [ "$WIFI_SIGNAL" -ge 50 ]; then WIFI_ICON="󰤥"
    elif [ "$WIFI_SIGNAL" -ge 25 ]; then WIFI_ICON="󰤢"
    elif [ "$WIFI_SIGNAL" -gt  0 ]; then WIFI_ICON="󰤟"
    else                                  WIFI_ICON="󰤯"
    fi
fi

# ─── Bluetooth ───────────────────────────────────────────────────────────────
if command -v bluetoothctl &>/dev/null && \
   bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    BLUETOOTH_ICON="󰂯"
else
    BLUETOOTH_ICON="󰂲"
fi

# ─── Battery ─────────────────────────────────────────────────────────────────
# Map 0-100% to 10% buckets and choose a glyph from the charging or discharging set.
if [ -d /sys/class/power_supply/BAT0 ]; then
    BAT_PCT=$(cat /sys/class/power_supply/BAT0/capacity)
    BAT_STAT=$(cat /sys/class/power_supply/BAT0/status)
    BUCKET=$(( BAT_PCT / 10 ))
    [ "$BUCKET" -gt 10 ] && BUCKET=10

    if [ "$BAT_STAT" = "Charging" ]; then
        case "$BUCKET" in
            0)  GLYPH="󰢟" ;;  1)  GLYPH="󰢜" ;;  2)  GLYPH="󰂆" ;;
            3)  GLYPH="󰂇" ;;  4)  GLYPH="󰂈" ;;  5)  GLYPH="󰢝" ;;
            6)  GLYPH="󰂉" ;;  7)  GLYPH="󰢞" ;;  8)  GLYPH="󰂊" ;;
            9)  GLYPH="󰂋" ;;  10) GLYPH="󰂅" ;;
        esac
    else
        case "$BUCKET" in
            0)  GLYPH="󰂎" ;;  1)  GLYPH="󰁺" ;;  2)  GLYPH="󰁻" ;;
            3)  GLYPH="󰁼" ;;  4)  GLYPH="󰁽" ;;  5)  GLYPH="󰁾" ;;
            6)  GLYPH="󰁿" ;;  7)  GLYPH="󰂀" ;;  8)  GLYPH="󰂁" ;;
            9)  GLYPH="󰂂" ;;  10) GLYPH="󰁹" ;;
        esac
    fi
    BAT_ICON="${GLYPH} ${BAT_PCT}%"
else
    BAT_ICON="󰚥 AC"
fi

# ─── Output ──────────────────────────────────────────────────────────────────
echo "${CPU_USAGE}|${RAM_USAGE}|${WIFI_ICON}|${BLUETOOTH_ICON}|${BAT_ICON}"

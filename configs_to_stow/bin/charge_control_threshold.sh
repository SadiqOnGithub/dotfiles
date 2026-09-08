#!/bin/bash
# Show or set battery charge start/stop thresholds when the kernel exposes them.

set -euo pipefail

usage() {
    echo "Usage: $0 [<start> <stop>]"
    echo "  no args     print current thresholds"
    echo "  start stop  resume charging at start%, stop charging at stop%"
    echo "Example: $0 40 80"
    echo "Thresholds must be integers 0-100, and start must be less than stop."
    exit 1
}

POWER_SUPPLY_DIR="${POWER_SUPPLY_DIR:-/sys/class/power_supply}"

discover_battery() {
    local bat
    for bat in "$POWER_SUPPLY_DIR"/BAT*; do
        [ -e "$bat" ] || continue
        if [ -f "$bat/charge_control_start_threshold" ] && [ -f "$bat/charge_control_end_threshold" ]; then
            START_FILE="$bat/charge_control_start_threshold"
            STOP_FILE="$bat/charge_control_end_threshold"
            BAT_PATH="$bat"
            return 0
        fi
    done
    for bat in "$POWER_SUPPLY_DIR"/BAT*; do
        [ -e "$bat" ] || continue
        if [ -f "$bat/charge_start_threshold" ] && [ -f "$bat/charge_stop_threshold" ]; then
            START_FILE="$bat/charge_start_threshold"
            STOP_FILE="$bat/charge_stop_threshold"
            BAT_PATH="$bat"
            return 0
        fi
    done
    return 1
}

read_value() {
    cat "$1" 2>/dev/null | tr -d '[:space:]'
}

show_current() {
    local start stop capacity status
    start="$(read_value "$START_FILE")"
    stop="$(read_value "$STOP_FILE")"
    if [ -z "$start" ] || [ -z "$stop" ]; then
        echo "Error: Failed to read threshold values." >&2
        exit 1
    fi
    echo "Battery: $(basename "$BAT_PATH")"
    echo "Start threshold: ${start}%  (resume charging at or below)"
    echo "Stop threshold:  ${stop}%  (stop charging at or above)"
    if [ -f "$BAT_PATH/capacity" ]; then
        capacity="$(read_value "$BAT_PATH/capacity")"
        echo "Capacity: ${capacity}%"
    fi
    if [ -f "$BAT_PATH/status" ]; then
        status="$(read_value "$BAT_PATH/status")"
        echo "Status: ${status}"
    fi
}

write_threshold() {
    local label="$1"
    local value="$2"
    local file="$3"
    echo "Setting ${label} threshold to ${value}%"
    if ! echo "$value" > "$file"; then
        echo "Error: Failed to set ${label} threshold." >&2
        exit 1
    fi
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
fi

if [ "$#" -ne 0 ] && [ "$#" -ne 2 ]; then
    usage
fi

if ! discover_battery; then
    echo "Charge start/stop thresholds are not supported on this system."
    echo "No charge_control_* or charge_start/stop_threshold files found under ${POWER_SUPPLY_DIR}/BAT*."
    exit 1
fi

if [ "$#" -eq 0 ]; then
    show_current
    exit 0
fi

START="$1"
STOP="$2"

if ! [[ "$START" =~ ^[0-9]+$ ]] || ! [[ "$STOP" =~ ^[0-9]+$ ]]; then
    echo "Error: Thresholds must be integers." >&2
    usage
fi

if [ "$START" -gt 100 ] || [ "$STOP" -gt 100 ]; then
    echo "Error: Thresholds must be between 0 and 100." >&2
    usage
fi

if [ "$START" -ge "$STOP" ]; then
    echo "Error: Start threshold must be less than stop threshold." >&2
    usage
fi

if [ ! -w "$START_FILE" ] || [ ! -w "$STOP_FILE" ]; then
    if [ "${EUID}" -ne 0 ]; then
        exec sudo POWER_SUPPLY_DIR="$POWER_SUPPLY_DIR" "$0" "$@"
    fi
fi

CURRENT_START="$(read_value "$START_FILE")"
CURRENT_STOP="$(read_value "$STOP_FILE")"
if [ -z "$CURRENT_START" ] || [ -z "$CURRENT_STOP" ]; then
    echo "Error: Failed to read current threshold values." >&2
    exit 1
fi

# Keep start < stop at every write. Raise the ceiling first, or lower the floor first.
if [ "$STOP" -le "$CURRENT_START" ]; then
    write_threshold "start" "$START" "$START_FILE"
    write_threshold "stop" "$STOP" "$STOP_FILE"
else
    write_threshold "stop" "$STOP" "$STOP_FILE"
    write_threshold "start" "$START" "$START_FILE"
fi

echo
echo "Thresholds set:"
show_current

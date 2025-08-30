#!/bin/bash

# Script to set battery charge start and stop thresholds

# Paths to threshold files
START_THRESHOLD="/sys/class/power_supply/BAT0/charge_control_start_threshold"
STOP_THRESHOLD="/sys/class/power_supply/BAT0/charge_control_end_threshold"

echo "Start: "; cat START_THRESHOLD


# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)."
    exit 1
fi


# Check if threshold files exist
if [ ! -f "$START_THRESHOLD" ] || [ ! -f "$STOP_THRESHOLD" ]; then
    echo "Error: Threshold files not found. Ensure /sys/class/power_supply/BAT0 exists."
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 <start_threshold> <stop_threshold>"
    echo "Example: $0 20 80"
    echo "Thresholds must be integers between 0 and 100, and start_threshold must be less than stop_threshold."
    exit 1
}

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    usage
fi

# Assign arguments to variables
START=$1
STOP=$2

# Validate input: Ensure arguments are integers
if ! [[ "$START" =~ ^[0-9]+$ ]] || ! [[ "$STOP" =~ ^[0-9]+$ ]]; then
    echo "Error: Thresholds must be integers."
    usage
fi

# Validate input: Ensure thresholds are between 0 and 100
if [ "$START" -lt 0 ] || [ "$START" -gt 100 ] || [ "$STOP" -lt 0 ] || [ "$STOP" -gt 100 ]; then
    echo "Error: Thresholds must be between 0 and 100."
    usage
fi

# Validate input: Ensure start_threshold is less than stop_threshold
if [ "$START" -ge "$STOP" ]; then
    echo "Error: Start threshold must be less than stop threshold."
    usage
fi

# Set the thresholds
echo "Setting charge start threshold to $START%"
echo "$START" > "$START_THRESHOLD"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set start threshold."
    exit 1
fi

echo "Setting charge stop threshold to $STOP%"
echo "$STOP" > "$STOP_THRESHOLD"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set stop threshold."
    exit 1
fi

echo "Thresholds set successfully:"
echo "Start threshold: $(cat $START_THRESHOLD)%"
echo "Stop threshold: $(cat $STOP_THRESHOLD)%"

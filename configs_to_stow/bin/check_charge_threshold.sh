#!/bin/bash

# Script to display battery charge start and stop thresholds

# Paths to threshold files
START_THRESHOLD="/sys/class/power_supply/BAT0/charge_control_start_threshold"
STOP_THRESHOLD="/sys/class/power_supply/BAT0/charge_control_end_threshold"

# Check if threshold files exist
if [ ! -f "$START_THRESHOLD" ] || [ ! -f "$STOP_THRESHOLD" ]; then
    echo "Error: Threshold files not found. Ensure /sys/class/power_supply/BAT0 exists."
    exit 1
fi

# Read and display the thresholds
START=$(cat "$START_THRESHOLD" 2>/dev/null)
STOP=$(cat "$STOP_THRESHOLD" 2>/dev/null)

# Check if reading was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to read threshold values."
    exit 1
fi

echo "Current Battery Thresholds:"
echo "Start threshold: $START%"
echo "Stop threshold: $STOP%"

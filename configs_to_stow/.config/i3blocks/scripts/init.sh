#!/bin/bash
set -euo pipefail

# Install dependencies for i3blocks statusbar scripts

packages=(
    acpi
    iw
    powerprofilesctl
    net-tools
    iputils-ping
)

echo "Installing i3blocks dependencies..."

sudo apt update -qq
sudo apt install -y "${packages[@]}"

# notify-send is part of libnotify
if ! command -v notify-send &>/dev/null; then
    sudo apt install -y libnotify-bin
fi

echo "Done. Restart i3blocks to pick up changes."

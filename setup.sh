#!/bin/bash

set -e

# This script installs the basic software, dependencies, sets up a service to start the server each time 
# the device is rebooted, etc. For a device with no display, this is sufficient to run the server.

INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"
SERVICE_USER="$(whoami)"
VENV_DIR="$HOME/venv"

echo "== G-Shock Server Installer for Linux =="

# Update & upgrade
if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y python3-pip python3-venv zip unzip \
        libfreetype6-dev libjpeg-dev zlib1g-dev libopenjp2-7-dev \
        libtiff5-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y python3-pip python3-venv zip unzip
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y python3-pip python3-venv zip unzip
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm python-pip python-virtualenv zip unzip
fi

# Setup virtual environment in home directory
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# Install dependencies
pip install --upgrade pip
pip install -r "$INSTALL_DIR/requirements.txt"

CONFIG_DIR="$HOME/.config/gshock"
CONFIG_FILE="$CONFIG_DIR/config.ini"

# Disable power-saving mode for the WiFi, otherwize it disconnects after some time.
echo 'sudo /sbin/iwconfig wlan0 power off' | sudo tee /etc/rc.local > /dev/null

mkdir -p "$CONFIG_DIR"
echo "[main]" > "$CONFIG_FILE"
echo excluded_watches = '["DW-H5600", "OCW-S400", "OCW-S400SG", "OCW-T200SB", "ECB-30", "ECB-20", "ECB-10", "ECB-50", "ECB-60", "ECB-70"]' >> "$CONFIG_FILE"

echo ""
echo "✅ Installation complete!"

# Create and enable systemd service
SERVICE_FILE="/etc/systemd/system/gshock.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python $INSTALL_DIR/gshock_server.py
WorkingDirectory=$INSTALL_DIR
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=5
User=$SERVICE_USER

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable gshock.service
sudo systemctl start gshock.service
echo "✅ gshock.service installed and started."

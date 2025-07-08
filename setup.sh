#!/bin/bash

set -e

INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"
SERVICE_USER="$(whoami)"

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

# Setup virtual environment
cd "$INSTALL_DIR"
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "✅ Installation complete!"

# Create and enable systemd service
SERVICE_FILE="/etc/systemd/system/gshock.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/gshock_server.py --multi-watch
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
# sudo systemctl status gshock.service

echo "✅ gshock.service installed and started."

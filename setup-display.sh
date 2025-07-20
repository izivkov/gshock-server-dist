#!/bin/bash

# Installs all display-related dependencies. While installing, it will ask you to select the display type.
# Note: You need to run both setup.sh and setup-display.sh.

set -e

echo "== Display setup =="

# Update & upgrade
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv zip unzip \
    libfreetype6-dev libjpeg-dev zlib1g-dev libopenjp2-7-dev \
    libtiff5-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev \
    python3-tk p7zip-full wget

# Install Python packages
pip install --upgrade pip
pip install spidev smbus smbus2 gpiozero numpy luma.oled luma.lcd lgpio pillow st7789

echo "Select your display type:"
echo "  1) waveshare (default)"
echo "  2) tft154"

read -p "Enter 1 or 2 [default: 1]: " DISPLAY_CHOICE

# If timed out or invalid input, fall back to default
if [[ "$DISPLAY_CHOICE" != "2" ]]; then
  DISPLAY_TYPE="waveshare"
else
  DISPLAY_TYPE="tft154"
fi

# Overwrite systemd service with display version
SERVICE_FILE="/etc/systemd/system/gshock.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python $INSTALL_DIR/gshock_server_display.py --display $DISPLAY_TYPE
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

echo "✅ Display setup complete!"

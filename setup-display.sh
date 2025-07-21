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
pip install spidev smbus smbus2 gpiozero numpy luma.oled luma.lcd lgpio pillow st7789 RPi.GPIO

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

# Update config.ini with the selected display type
CONFIG_FILE="./config.ini"

# Validate DISPLAY_TYPE
case "$DISPLAY_TYPE" in
    waveshare|tft154|mock)
        ;;
    *)
        echo "Error: DISPLAY_TYPE must be one of: waveshare, tft154, mock"
        exit 1
        ;;
esac

echo "Display type set to: $DISPLAY_TYPE"

echo "[main]" > "$CONFIG_FILE"
echo "display = $DISPLAY_TYPE" >> "$CONFIG_FILE"
echo excluded_watches = '["OCW-S400-2AJF", "OCW-S400SG-2AJR", "OCW-T200SB-1AJF", "ECB-30", "ECB-20", "ECB-10", "ECB-50", "ECB-60", "ECB-70"]' >> "$CONFIG_FILE"

# end of config.ini update

# Overwrite systemd service with display version
SERVICE_FILE="/etc/systemd/system/gshock.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python $INSTALL_DIR/gshock_server_display.py
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

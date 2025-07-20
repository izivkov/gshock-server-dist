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

# Update config.ini with the selected display type
CONFIG_FILE="config.ini"
SECTION="[main]"
KEY="display"

# Validate DISPLAY_TYPE
case "$DISPLAY_TYPE" in
    waveshare|tft154|mock)
        ;;
    *)
        echo "Error: DISPLAY_TYPE must be one of: waveshare, tft154, mock"
        exit 1
        ;;
esac

# Create file if it doesn't exist
[ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"

# Check if section exists
if ! grep -q "^\[main\]" "$CONFIG_FILE"; then
    echo "[main]" >> "$CONFIG_FILE"
fi

# Update or insert key under [main]
awk -v section="$SECTION" -v key="$KEY" -v value="$DISPLAY_TYPE" '
BEGIN { found=0; updated=0 }
/^\[.*\]/ {
    if (found && !updated) {
        print key " = " value
        updated = 1
    }
    if ($0 == section) {
        found = 1
    } else {
        found = 0
    }
}
found && $1 == key {
    print key " = " value
    updated = 1
    next
}
{ print }
END {
    if (!updated && found) {
        print key " = " value
    }
}
' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
# end of config.ini update
echo "Display type set to: $DISPLAY_TYPE"

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

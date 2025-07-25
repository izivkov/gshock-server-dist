#!/bin/bash

set -e

# This script installs the basic software, dependencies, sets up a service to start the server each time 
# the device is rebooted, etc. For a device with no display, this is sufficient to run the server.

INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"
SERVICE_USER="$(whoami)"
VENV_DIR="$HOME/venv"
BOOT_SCRIPT="$HOME/onboot.sh"
LOG_DIR="$HOME/logs"

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

# run commands on boot
tee "$BOOT_SCRIPT" > /dev/null <<EOL
#!/bin/bash

# Wait for wlan0 to be ready (max 20 seconds)
for i in {1..20}; do
    if /sbin/iw dev wlan0 info > /dev/null 2>&1; then
        echo "wlan0 detected."
        break
    fi
    echo "Waiting for wlan0... ($i)"
    sleep 1
done

# Run your commands here
echo "Disabling Wi-Fi power save"
sudo /usr/sbin/iw wlan0 set power_save off >> /home/pi/boot.log 2>&1
EOL

chmod +x "$BOOT_SCRIPT"

# Create and enable BOOT service
BOOT_SERVICE_FILE="/etc/systemd/system/user-boot-script.service"
sudo tee "$BOOT_SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Run Pi user’s boot script
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/bin/bash -c "sudo -u pi /home/pi/onboot.sh"
Type=oneshot
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable user-boot-script.service


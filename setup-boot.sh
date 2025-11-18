#!/bin/bash

set -e

BOOT_SCRIPT="$HOME/onboot.sh"
LOG_DIR="$HOME/logs"

tee "$BOOT_SCRIPT" > /dev/null <<EOL
#!/bin/bash

# Unblock all rfkill (WiFi, Bluetooth, etc.)
sudo rfkill unblock all

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

sleep 10
sudo systemctl restart gshock.service >> /home/pi/boot.log 2>&1

EOL

chmod +x "$BOOT_SCRIPT"

# Create and enable BOOT service
BOOT_SERVICE_FILE="$USER_SYSTEMD_DIR/user-boot-script.service"
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
WantedBy=default.target
EOL

# Enable the service
sudo systemctl daemon-reload
sudo systemctl --user enable user-boot-script.service
sudo systemctl start user-boot-script.service


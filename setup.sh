#!/bin/bash

echo "== G-Shock Server Installer for Raspberry Pi Zero =="

# Update & upgrade
sudo apt update && sudo apt upgrade -y

# Install some tools
sudo apt install -y python3-pip
sudo apt install -y zip unzip
sudo apt install -y libfreetype6-dev
sudo apt install -y libjpeg-dev zlib1g-dev libopenjp2-7-dev libtiff5-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk

# Install dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt

echo ""
echo "✅ Installation complete!"

# Create and enable systemd service
cat << EOL | sudo tee /etc/systemd/system/gshock.service > /dev/null
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=python3 /home/pi/gshock-server-dist/gshock_server.py --multi-watch
WorkingDirectory=/home/pi/gshock-server-dist
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
RestartSec=5
User=pi

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable gshock.service
sudo systemctl start gshock.service
# sudo systemctl status gshock.service

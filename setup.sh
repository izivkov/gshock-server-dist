#!/bin/bash

echo "== G-Shock Server Installer for Raspberry Pi Zero =="

# Update & upgrade
sudo apt update && sudo apt upgrade -y

# Install some tools
sudo apt install -y python3-pip
sudo apt update
sudo apt install -y zip unzip

# Install dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Create and enable systemd service
cat << EOL | sudo tee /etc/systemd/system/gshock.service > /dev/null
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/gshock-server-dist/gshock-server.py --multi-watch
WorkingDirectory=/home/pi/gshock-server-dist
Restart=always
User=pi
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable gshock.service
sudo systemctl start gshock.service
# sudo systemctl status gshock.service

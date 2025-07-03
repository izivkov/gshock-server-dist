#!/bin/bash

echo "== G-Shock Server Installer for Raspberry Pi Zero =="

# Update & upgrade
sudo apt update && sudo apt upgrade -y

# Install some tools
sudo apt install -y python3-pip
sudo apt update
sudo apt install -y zip unzip
sudo apt install -y python3-pil python3-setuptools libjpeg-dev zlib1g-dev

# Setup virtual environmsnent
sudo apt install python3-venv
python3 -m venv venv
source venv/bin/activate
# pip install -r requirements.txt

# Install dependencies
pip3 install --upgrade pip

pip3 install pytz
pip3 install bleak>=1.0
pip3 install gshock-api>=2.0.6
pip3 install --break-system-packages luma.oled

# Create and enable systemd service
cat << EOL | sudo tee /etc/systemd/system/gshock.service > /dev/null
[Unit]
Description=G-Shock Time Server
After=network.target

[Service]
ExecStart=python3 /home/pi/gshock-server-dist/gshock_server.py --multi-watch
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

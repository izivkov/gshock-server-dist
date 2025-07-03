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
# ----------------------
# Install dbus-fast (dependency of bleak)
# ----------------------
echo ""
echo "== Installing dbus-fast (for bleak) =="

cd /tmp
DBUS_FAST_WHL=$(find . -name "dbus_fast*.whl" | head -n 1)

if [ -f "$DBUS_FAST_WHL" ]; then
    echo "-> Installing prebuilt dbus-fast wheel: $DBUS_FAST_WHL"
    pip3 install --break-system-packages "$DBUS_FAST_WHL"
else
    echo "-> No prebuilt dbus-fast wheel found. Installing from source (this may take several minutes)..."
    pip3 install --break-system-packages dbus-fast
fi

# ----------------------
# Install bleak
# ----------------------
echo ""
echo "== Installing bleak =="
pip3 install --break-system-packages bleak


# ----------------------
# Install Pillow & luma.oled
# ----------------------
echo ""
echo "== Installing luma.oled and dependencies =="

# Install system packages to avoid compiling Pillow
sudo apt install -y python3-pil libjpeg-dev zlib1g-dev

cd /tmp
LUMA_WHL=$(find . -name "luma.oled*.whl" | head -n 1)

if [ -f "$LUMA_WHL" ]; then
    echo "-> Installing prebuilt luma.oled wheel: $LUMA_WHL"
    pip3 install --break-system-packages "$LUMA_WHL"
else
    echo "-> No prebuilt luma.oled wheel found. Installing via pip (should be fast since Pillow is preinstalled)..."
    pip3 install --break-system-packages luma.oled
fi

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

#!/bin/bash
set -e

# G-Shock Display Setup (headless, uv-native, systemd user service)

echo "== G-Shock Display Setup =="

INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"
SERVICE_USER="$(whoami)"
LAUNCHER="$HOME/.local/bin/start_gshock_display.sh"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$USER_SYSTEMD_DIR/gshock_display.service"

# Ensure Python and basic dependencies exist
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3 is required. Please install it first."
    exit 1
fi

# Ensure uv CLI is installed (system-wide or user)
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv CLI..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Ensure system packages are available
echo "== Installing required system libraries =="
sudo apt-get update -qq

sudo apt install -y \
  swig liblgpio-dev \
  build-essential python3-dev python3-numpy cython3 \
  libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev \
  libopenjp2-7-dev libtiff-dev libwebp-dev tcl-dev tk-dev \
  libdbus-1-dev libglib2.0-dev
  
sudo apt-get -y autoremove

rm -rf /home/pi/venv
uv venv --system-site-packages /home/pi/venv

# Sync display-related Python dependencies (auto env handled by uv)
echo "== Installing display-related Python packages with uv =="
uv sync --quiet
uv pip install spidev smbus smbus2 gpiozero luma.oled luma.lcd lgpio pillow st7789 RPi.GPIO

# Ask user for display type
echo "Select your display type:"
echo "  1) waveshare (default)"
echo "  2) tft154"
read -p "Enter 1 or 2 [default: 1]: " DISPLAY_CHOICE

if [[ "$DISPLAY_CHOICE" != "2" ]]; then
    DISPLAY_TYPE="waveshare"
else
    DISPLAY_TYPE="tft154"
fi

echo "Display type set to: $DISPLAY_TYPE"

# Create launcher script
mkdir -p "$(dirname "$LAUNCHER")"
cat > "$LAUNCHER" <<EOL
#!/bin/bash
export PATH="\$HOME/.local/bin:\$PATH"
uv run "$INSTALL_DIR/gshock_server_display.py" --display $DISPLAY_TYPE
EOL
chmod +x "$LAUNCHER"

# Create systemd user service
mkdir -p "$USER_SYSTEMD_DIR"
cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=G-Shock Display Server
After=network.target

[Service]
ExecStart=$LAUNCHER
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOL

# Enable linger so the service runs without login
loginctl enable-linger "$SERVICE_USER"

# Enable and start the service
systemctl --user daemon-reload
systemctl --user enable gshock_display.service
systemctl --user start gshock_display.service

echo "✅ G-Shock display server installed and started (via systemd user service)."
echo "Manage with: systemctl --user status gshock_display.service"

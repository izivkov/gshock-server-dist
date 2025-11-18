#!/bin/bash
set -e

# G-Shock Server Installer for Raspberry Pi (headless, uv-native, systemd user service)

INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"
SERVICE_USER="$(whoami)"
LAUNCHER="$HOME/.local/bin/start_gshock.sh"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$USER_SYSTEMD_DIR/gshock.service"
VENV_DIR="$HOME/venv"

echo "== G-Shock Server Installer =="

# Ensure Python3 and Git are available
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3 is required. Please install Python3 first."
    exit 1
fi
if ! command -v git >/dev/null 2>&1; then
    echo "Git is required. Installing..."
    sudo apt-get update && sudo apt-get install -y git
fi

# Install uv if missing
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv globally..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Setup virtual environment in home directory
if [ ! -d "$VENV_DIR" ]; then
  uv venv --system-site-packages "$VENV_DIR"
fi
. "$VENV_DIR/bin/activate"

echo "== Installing system dependencies for Pillow and other libs =="
sudo apt update
sudo apt install -y \
  build-essential python3-dev cython3 \
  libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev \
  libopenjp2-7-dev libtiff-dev libwebp-dev tcl-dev tk-dev \
  libdbus-1-dev libglib2.0-dev coreutils

# Install dependencies using uv
echo "== Installing dependencies via uv =="
cd "$INSTALL_DIR"
uv sync -q

# Optional: disable WiFi power-saving
if command -v iwconfig >/dev/null 2>&1; then
    echo "Disabling WiFi power-saving..."
    sudo bash -c 'echo "/sbin/iwconfig wlan0 power off" >> /etc/rc.local'
else
    echo "Skipping WiFi power-saving (iwconfig not found)."
fi

# Create launcher script that runs server via uv
mkdir -p "$(dirname "$LAUNCHER")"
cat > "$LAUNCHER" <<EOL
#!/bin/bash
export PATH="\$HOME/.local/bin:\$PATH"
cd "$INSTALL_DIR"
uv run gshock_server.py
EOL
chmod +x "$LAUNCHER"

# Create systemd user service
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


#!/bin/bash
set -x
set -e

# Change to the project root directory containing pyproject.toml and requirements.txt
cd "$(dirname "$0")"

# Update package list and install system dependencies needed for building Python packages
sudo apt-get update
sudo apt-get install -y build-essential python3-dev python3-venv python3-pip curl libffi-dev

# Check if uv is installed, if not install it using the official install script
if ! command -v uv &> /dev/null
then
    echo "uv not found, installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Add uv to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"
fi

# Remove old or broken .venv directory to start fresh
rm -rf .venv

# Install dependencies from requirements.txt using uv (creates .venv automatically)
uv add -r requirements.txt

#!/bin/bash
set -x
set -e

# Change to the project root directory containing pyproject.toml and requirements.txt
cd "$(dirname "$0")"

# Check if uv is installed, if not install it using pip or the official installer
if ! command -v uv &> /dev/null
then
    echo "uv not found, installing uv..."
    # Option 1: Install uv using pip (requires python and pip installed)
    # pip install --user uv

    # Alternatively, you can use the official install script for macOS/Linux:
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Make sure ~/.local/bin is in PATH for pip user installs:
    export PATH="$HOME/.local/bin:$PATH"
fi

# Remove old or broken .venv directory to start fresh
rm -rf .venv

# Install dependencies from requirements.txt using uv (creates .venv automatically)
uv add -r requirements.txt


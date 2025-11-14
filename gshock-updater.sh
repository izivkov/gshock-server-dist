#!/bin/bash

set -e

# This script will set the device to automatically update its software if a new version is available on GitHub.
# It will then restart the server, so you will always be running the latest version. The scripts sets us a cron job to
# run periodically and check for new tags on the `gshock-server-dist` GitHub repository.

set -e

VENV_DIR="$HOME/venv"
REPO_NAME="gshock-server-dist"
REPO_URL="https://github.com/izivkov/gshock-server-dist.git"
REPO_DIR="$HOME/$REPO_NAME"
LAST_TAG_FILE="$HOME/.config/gshock-updater/last-tag"
LOG_FILE="$HOME/logs/gshock-updater.log"
INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"

mkdir -p "$(dirname "$LAST_TAG_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Clone repo if missing
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Fetch tags and determine latest
git fetch --tags --force
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "No tags found in repository."
    exit 1
fi

# Read last synced tag
LAST_SYNCED_TAG=""
if [ -f "$LAST_TAG_FILE" ]; then
    LAST_SYNCED_TAG=$(cat "$LAST_TAG_FILE")
fi

# Update if a new tag is found
if [ "$LATEST_TAG" != "$LAST_SYNCED_TAG" ]; then
    echo "Updating to tag: $LATEST_TAG"
    git reset --hard "$LATEST_TAG"
    git clean -fd
    echo "$LATEST_TAG" > "$LAST_TAG_FILE"

    echo "Updating API's"
    source "$VENV_DIR/bin/activate"
    pip install -r "$INSTALL_DIR/requirements.txt"

    echo "Restarting gshock.service"
    sudo systemctl restart gshock.service
else
    echo "Already up to date with tag: $LATEST_TAG"
fi

# Ensure cron job is present
CRON_JOB="*/60 * * * * $REPO_DIR/gshock-updater.sh >> $LOG_FILE 2>&1"
( crontab -l 2>/dev/null | grep -Fv "$REPO_NAME/gshock-updater.sh" ; echo "$CRON_JOB" ) | crontab -

#!/bin/bash
set -e

REPO_DIR="~/"
REPO_URL="https://github.com/izivkov/gshock-server-dist.git"
LAST_TAG_FILE="$HOME/last-tag"

# Make sure last-tag directory exists
mkdir -p "$(dirname "$LAST_TAG_FILE")"

# Clone if repo is missing
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# Fetch tags only
git fetch --tags

# Get latest tag name
LATEST_TAG=$(git tag | sort -V | tail -n 1)

# Read last deployed tag
if [ -f "$LAST_TAG_FILE" ]; then
    LAST_TAG=$(cat "$LAST_TAG_FILE")
else
    LAST_TAG=""
fi

# Deploy if new
if [ "$LATEST_TAG" != "$LAST_TAG" ]; then
    echo "New tag found: $LATEST_TAG"
    rm -rf "$DIST_DIR"/*
    git fetch --all
    git checkout "$LATEST_TAG"
    echo "$LATEST_TAG" > "$LAST_TAG_FILE"

    echo "Restarting gshock-server.service"
    sudo systemctl restart gshock-server.service
else
    echo "No update needed. Current tag: $LATEST_TAG"
fi

# Add cron job to run updater every 30 minutes
CRON_JOB="*/3 * * * * /usr/local/bin/gshock-updater.sh >> /var/log/gshock-updater.log 2>&1"

# Check if the cron job already exists
crontab -l 2>/dev/null | grep -F "$CRON_JOB" >/dev/null

if [ $? -ne 0 ]; then
    # Append the cron job if it's not found
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added."
else
    echo "Cron job already exists. Skipping."
fi


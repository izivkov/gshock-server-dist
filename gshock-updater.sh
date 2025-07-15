#!/bin/bash
set -e

DIST_DIR="gshock-server-dist"
REPO_DIR="~/"
REPO_URL="https://github.com/izivkov/gshock-server-dist.git"
LAST_TAG_FILE="$HOME/last-tag"

LOG_FILE="$HOME/logs/gshock-updater.log"
mkdir -p "$(dirname "$LOG_FILE")"

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
    git fetch --tags --force

    # Optional: ensure you're clean before switching
    git reset --hard
    git clean -fd

    git checkout "$LATEST_TAG"
    
    echo "$LATEST_TAG" > "$LAST_TAG_FILE"

    echo "Restarting gshock.service"
    sudo systemctl restart gshock.service
else
    echo "No update needed. Current tag: $LATEST_TAG"
fi

# Add cron job to run updater every 30 minutes
CRON_JOB="*/1 * * * * $DIST_DIR/gshock-updater.sh >> $LOG_FILE 2>&1"

# Get current crontab or fallback to empty
CURRENT_CRON=$(crontab -l 2>/dev/null)

# Debug: show current crontab
echo "Current crontab:"
echo "$CURRENT_CRON"
echo "-----"

# Check if job already exists
if echo "$CURRENT_CRON" | grep -Fq "$CRON_JOB"; then
    echo "Cron job already exists. Skipping."
else
    # Add job
    (echo "$CURRENT_CRON"; echo "$CRON_JOB") | crontab -
    echo "Cron job added."
fi

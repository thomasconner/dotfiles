#!/bin/bash

# === CONFIGURATION ===
TIMESHIFT_DIR="/mnt/Secondary/timeshift/snapshots"
RCLONE_REMOTE="b2:ConnerTechnology/backups/linux-desktop/timeshift/snapshots"
LOG_FILE="/var/log/timeshift-to-b2.log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# === FUNCTIONS ===

log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# === START BACKUP ===

log "Starting Timeshift backup sync to Backblaze B2..."

if [ ! -d "$TIMESHIFT_DIR" ]; then
    log "ERROR: Timeshift directory not found: $TIMESHIFT_DIR"
    exit 1
fi

# Sync using rclone (you can use copy instead of sync if you don't want deletions)
rclone sync "$TIMESHIFT_DIR" "$RCLONE_REMOTE" --progress --log-file="$LOG_FILE" --log-level INFO

if [ $? -eq 0 ]; then
    log "Backup sync completed successfully."
else
    log "ERROR: Backup sync failed."
    exit 1
fi

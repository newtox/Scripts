#!/bin/bash

LOG_FILE="/var/log/mog_update.log"
echo "$(date) - Script execution started" >> "$LOG_FILE"

if [ ! -f ".env" ]; then
    echo "$(date) - Error: .env file not found." >> "$LOG_FILE"
    exit 1
fi
source .env

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
    echo "$(date) - Error: GITHUB_USERNAME or GITHUB_PAT not set in .env." >> "$LOG_FILE"
    exit 1
fi

# Check if tmux session exists
if ! tmux has-session -t mog 2>/dev/null; then
    echo "$(date) - Tmux session 'mog' does not exist. Creating..." >> "$LOG_FILE"
    tmux new-session -s mog -d
    tmux send-keys -t mog "cd /root/Mog" C-m
    sleep 5
else
    echo "$(date) - Tmux session 'mog' already exists. Using existing session." >> "$LOG_FILE"
    tmux send-keys -t mog C-l  # Clear the screen to start fresh
fi

# Git pull
tmux send-keys -t mog "git pull" C-m
sleep 10

tmux send-keys -t mog "$GITHUB_USERNAME" C-m
sleep 5

tmux send-keys -t mog "$GITHUB_PAT" C-m
sleep 5

# Wait for pull
sleep 20

# Check git status
tmux send-keys -t mog "git status" C-m
sleep 5

# Start Dart
tmux send-keys -t mog "dart run bin/main.dart" C-m
echo "$(date) - Attempted to start Dart application." >> "$LOG_FILE"

# Wait for Dart to start
sleep 30

# Check if Dart is running
if ! pgrep -f "dart run bin/main.dart" > /dev/null; then
    echo "$(date) - Warning: Dart process not found. Attempting restart..." >> "$LOG_FILE"
    tmux send-keys -t mog "dart run bin/main.dart" C-m
    sleep 20

    if ! pgrep -f "dart run bin/main.dart" > /dev/null; then
        echo "$(date) - Restart failed. Dart process still not running." >> "$LOG_FILE"
    else
        echo "$(date) - Restart successful, Dart process now running." >> "$LOG_FILE"
    fi
else
    echo "$(date) - Dart process found running." >> "$LOG_FILE"
fi

# Final check or cleanup
sleep 10
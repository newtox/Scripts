#!/bin/bash

LOG_FILE="/root/mog_update.log"
echo_and_log() {
    # Function to echo to console and log to file
    echo "$1"
    echo "$(date) - $1" >> "$LOG_FILE"
}

echo_and_log "Script execution started"

if [ ! -f ".env" ]; then
    echo_and_log "Error: .env file not found."
    exit 1
fi

source .env

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
    echo_and_log "Error: GITHUB_USERNAME or GITHUB_PAT not set in .env."
    exit 1
fi

# Check if tmux session exists
if ! tmux has-session -t mog 2>/dev/null; then
    echo_and_log "Tmux session 'mog' does not exist. Creating..."
    tmux new-session -s mog -d
    tmux send-keys -t mog "cd /root/Mog" C-m
    sleep 2  # Adjusted to a shorter sleep
else
    echo_and_log "Tmux session 'mog' already exists. Using existing session."
    tmux send-keys -t mog C-l  # Clear the screen to start fresh
fi

# Git pull and log output
GIT_OUTPUT=$(tmux send-keys -t mog "git pull" C-m 2>&1)
echo_and_log "Git pull output: $GIT_OUTPUT"

# Check if git pull was successful
if [[ $? -ne 0 ]]; then
    echo_and_log "Error: Git pull failed."
    exit 1
fi

tmux send-keys -t mog "$GITHUB_USERNAME" C-m
tmux send-keys -t mog "$GITHUB_PAT" C-m

# Wait for pull
sleep 5

# Check git status and log output
STATUS_OUTPUT=$(tmux send-keys -t mog "git status" C-m 2>&1)
echo_and_log "Git status output: $STATUS_OUTPUT"

# Start Dart and log output
DART_OUTPUT=$(tmux send-keys -t mog "dart run bin/main.dart" C-m 2>&1)
echo_and_log "Dart start output: $DART_OUTPUT"

# Wait for Dart to start
sleep 5

# Check if Dart is running
if ! pgrep -f "dart run bin/main.dart" > /dev/null; then
    echo_and_log "Warning: Dart process not found. Attempting restart..."
    DART_RESTART_OUTPUT=$(tmux send-keys -t mog "dart run bin/main.dart" C-m 2>&1)
    echo_and_log "Dart restart output: $DART_RESTART_OUTPUT"
    
    sleep 5

    if ! pgrep -f "dart run bin/main.dart" > /dev/null; then
        echo_and_log "Restart failed. Dart process still not running."
    else
        echo_and_log "Restart successful, Dart process now running."
    fi
else
    echo_and_log "Dart process found running."
fi

# Final check or cleanup
echo_and_log "Script execution completed."
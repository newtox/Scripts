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
    sleep 2  # Short sleep to allow session to start
else
    echo_and_log "Tmux session 'mog' already exists. Using existing session."
    tmux send-keys -t mog C-l  # Clear the screen to start fresh
fi

# Git pull
tmux send-keys -t mog "git pull" C-m
sleep 2  # Wait for command to execute

# Capture the output of the last command
GIT_OUTPUT=$(tmux capture-pane -t mog -pS -100) # Capture last 100 lines
echo_and_log "Git pull output:\n$GIT_OUTPUT"

# Check if git pull was successful
if [[ $? -ne 0 ]]; then
    echo_and_log "Error: Git pull failed."
    exit 1
fi

tmux send-keys -t mog "$GITHUB_USERNAME" C-m
tmux send-keys -t mog "$GITHUB_PAT" C-m

# Wait for authentication (if needed)
sleep 5

# Check git status
tmux send-keys -t mog "git status" C-m
sleep 2  # Wait for command to execute

# Capture the output of the last command
STATUS_OUTPUT=$(tmux capture-pane -t mog -pS -100)
echo_and_log "Git status output:\n$STATUS_OUTPUT"

# Start Dart
tmux send-keys -t mog "dart run bin/main.dart" C-m
sleep 2  # Wait for Dart to start

# Capture the output of the last command
DART_OUTPUT=$(tmux capture-pane -t mog -pS -100)
echo_and_log "Dart start output:\n$DART_OUTPUT"

# Check if Dart is running
if ! pgrep -f "dart run bin/main.dart" > /dev/null; then
    echo_and_log "Warning: Dart process not found. Attempting restart..."
    tmux send-keys -t mog "dart run bin/main.dart" C-m
    sleep 2

    # Capture the output of the restart
    DART_RESTART_OUTPUT=$(tmux capture-pane -t mog -pS -100)
    echo_and_log "Dart restart output:\n$DART_RESTART_OUTPUT"
    
    sleep 5  # Wait before checking again

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

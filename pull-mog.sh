#!/bin/bash

# Define variables
REPO_DIR="/Mog/"      # Path to your Git repository
SESSION_NAME="mog"        # tmux session name
DART_SCRIPT="/Mog/bin/main.dart"     # Your Dart script file
LOG_FILE="/Mog/mog_log.log"   # Log file to track script activity

# Navigate to the Git repository
cd "$REPO_DIR" || { echo "Failed to navigate to repo. Exiting..."; exit 1; }

# Reset any local changes and pull the latest updates from GitHub
echo "Pulling latest changes from GitHub..." | tee -a "$LOG_FILE"
git reset --hard
git pull origin main >> "$LOG_FILE" 2>&1

# Check if Git pull was successful
if [ $? -eq 0 ]; then
    echo "Git pull successful. Preparing to restart Dart process..." | tee -a "$LOG_FILE"

    # Check if tmux session already exists
    tmux has-session -t "$SESSION_NAME" 2>/dev/null
    if [ $? != 0 ]; then
        echo "No existing tmux session found. Starting a new session..." | tee -a "$LOG_FILE"

        # Start a new tmux session and run the Dart process in it
        tmux new-session -d -s "$SESSION_NAME"
        tmux send-keys -t "$SESSION_NAME" "dart $DART_SCRIPT" C-m

        echo "Dart process started in new tmux session." | tee -a "$LOG_FILE"
    else
        echo "Tmux session found. Restarting Dart process..." | tee -a "$LOG_FILE"

        # Kill the current Dart process running in tmux
        tmux send-keys -t "$SESSION_NAME" C-c   # Send Ctrl+C to stop current process
        sleep 2  # Give it a couple of seconds to stop

        # Restart the Dart process
        tmux send-keys -t "$SESSION_NAME" "dart $DART_SCRIPT" C-m

        echo "Dart process restarted in tmux session." | tee -a "$LOG_FILE"
    fi
else
    echo "Git pull failed. No changes applied." | tee -a "$LOG_FILE"
fi

echo "Script execution completed." | tee -a "$LOG_FILE"

#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Checkout branch from this the PR in the clipboard
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ✅

# Get the content from the clipboard
clip_content=$(pbpaste)  # Use 'xclip -o' on Linux instead of 'pbpaste'

# Parse the values using awk
repo_name=$(echo "$clip_content" | awk -F'/' '{print $5}')  # Extract "cal.com"
pull_number=$(echo "$clip_content" | awk -F'/' '{for(i=1;i<=NF;i++){if($i=="pull"){print $(i+1)}}}')  # Extract "19697"

# Check if values were extracted successfully
if [[ -z "$repo_name" || -z "$pull_number" ]]; then
  echo "Failed to parse repository name or pull request number."
  exit 1
fi

# Change directory to the workspace
cd ~/workspace/"$repo_name" || { echo "Directory ~/workspace/$repo_name not found."; exit 1; }

# Run the commands
git checkout HEAD -- yarn.lock && gh pr checkout "$pull_number"

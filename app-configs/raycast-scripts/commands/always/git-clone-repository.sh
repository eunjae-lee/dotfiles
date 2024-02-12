#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Git Clone Repository
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 👨🏻‍💻
# @raycast.argument1 { "type": "text", "placeholder": "Repo URL" }

# Documentation:
# @raycast.author Eunjae Lee

cd ~/workspace
git clone "$1"
repo_name=$(basename "$1" .git)
cd "$repo_name"
code .
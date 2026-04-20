#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open in Zed from clipboard
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📝
# @raycast.packageName Developer

# Documentation:
# @raycast.author Eunjae Lee

path=$(pbpaste | tr -d '\n')

if [ -z "$path" ]; then
  echo "Clipboard is empty"
  exit 1
fi

# Expand ~ to $HOME
path="${path/#\~/$HOME}"

if [ ! -e "$path" ]; then
  echo "Path does not exist: $path"
  exit 1
fi

open -a Zed "$path"

#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Update Now Tasks
# @raycast.mode inline
# @raycast.refreshTime 15m

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Eunjae Lee

if [[ $(hostname) == Eunjaes-Mac-mini* ]]; then
  shortcuts run "Update Now Tasks"
fi

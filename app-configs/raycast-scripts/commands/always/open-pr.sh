#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Pull Request
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "PR number?" }

open "https://github.com/calcom/cal.com/pull/$1"

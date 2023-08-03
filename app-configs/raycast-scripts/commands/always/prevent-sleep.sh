#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Prevent Sleep
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "How many hours?" }

open -g "lungo:activate?hours=$1"
#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Get Week Number
# @raycast.mode compact
# @raycast.icon 🗓️

source ~/.zshrc
ej week | tr -d '\n' | pbcopy

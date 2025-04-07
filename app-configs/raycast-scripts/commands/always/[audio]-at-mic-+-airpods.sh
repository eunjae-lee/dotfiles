#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title [Audio] AT Mic + AirPods
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Eunjae Lee

shortcuts run "AirPods - Transparent"
SwitchAudioSource -t input -s 'AT2020USB+'

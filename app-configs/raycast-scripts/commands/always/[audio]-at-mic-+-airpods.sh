#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title [Audio] AT Mic + AirPods
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Eunjae Lee

SwitchAudioSource -t input -s 'AT2020USB+'
SwitchAudioSource -t output -s 'Eunjae’s AirPods Pro'

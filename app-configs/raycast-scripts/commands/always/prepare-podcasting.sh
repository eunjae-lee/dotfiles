#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Prepare Podcasting
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🎙

open "raycast://extensions/raycast/system/quit-all-applications"

echo "Caffeinate for 1 hour"
caffeinate -dmi -t 3600

SwitchAudioSource -t input -s 'AT2020USB+'

open -a "Notes"
open -a "QuickTime Player"

zed ~/workspace/eunjae-dev-nuxt/

open https://podcast.adobe.com/enhance

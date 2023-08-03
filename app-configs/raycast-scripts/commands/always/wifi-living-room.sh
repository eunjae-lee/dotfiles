#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Wifi: Living room
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📶

source ../../.env
m wifi connect mps "${WIFI_LIVING_ROOM_PASSWORD}"

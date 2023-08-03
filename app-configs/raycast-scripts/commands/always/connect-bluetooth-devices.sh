#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Re-connect apple keyboard and trackpad
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ⌨️

blueutil --unpair b0-be-83-f1-90-b4
blueutil --unpair 14-c2-13-ee-5e-21

blueutil --connect b0-be-83-f1-90-b4
blueutil --connect 14-c2-13-ee-5e-21

#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Morning Routine
# @raycast.mode compact

cd /Users/eunjae/workspace/morning-routine
xc next

file="/tmp/morning-routine-$(date +'%Y-%m-%d').txt"
echo "Morning Routine (step #$(cat "$file"))"
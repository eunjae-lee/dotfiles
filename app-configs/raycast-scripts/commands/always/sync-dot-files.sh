#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sync dotfiles
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔄

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

(cd $SCRIPT_DIR && cd ../../../dotfiles && git add . && git commit -m "update" && git pull --no-edit && git push)
(cd $SCRIPT_DIR && cd ../../../dotfiles && git pull)

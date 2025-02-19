#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sync notes
# @raycast.mode inline
# @raycast.refreshTime 5m

# Optional parameters:
# @raycast.icon 🔄

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

(cd $SCRIPT_DIR && cd ../../../../../notes && git add . && git commit -m "update" && git pull --no-edit && git push)
(cd $SCRIPT_DIR && cd ../../../../../notes && git pull)

#!/bin/bash
open -a iTerm
sleep 2
osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with default profile
    tell current session to write text "zellij --layout ~/workspace/dotfiles/app-configs/zellij/mac_mini.kdl"
  end tell
end tell
EOF

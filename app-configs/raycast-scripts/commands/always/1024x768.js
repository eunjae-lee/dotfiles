#!/usr/bin/env node

// @raycast.title Resize to 1024x768
//
// @raycast.mode fullOutput
// @raycast.icon 🗓
// @raycast.schemaVersion 1

const { runAppleScript } = require("../../lib");

runAppleScript(`
tell application "System Events"
    set frontmostProcess to first process where it is frontmost
    set visible of frontmostProcess to false
    repeat while (frontmostProcess is frontmost)
        delay 0.2
    end repeat
    set secondFrontmost to name of first process where it is frontmost
    set frontmost of frontmostProcess to true
end tell

tell application (path to frontmost application as text)
    set bounds of front window to {0, 0, 1024, 768}
end tell
`);

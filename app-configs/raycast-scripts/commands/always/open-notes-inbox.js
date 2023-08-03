#!/usr/bin/env node

// @raycast.title Open Notes Inbox
//
// @raycast.mode compact
// @raycast.icon 🗓
// @raycast.schemaVersion 1

const { runAppleScript } = require("../../lib");

runAppleScript(`
tell application "Notes"
    tell folder "Inbox"
        show note 1
    end tell
end tell
`);

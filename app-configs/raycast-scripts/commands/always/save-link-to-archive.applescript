#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Save Reference
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Title" }
# @raycast.argument2 { "type": "text", "placeholder": "URL" }

on run argv
log "Hello World! Argument1 value: " & ( item 1 of argv )
	tell application "Reminders"
		set mylist to list "References"
		tell mylist
			make new reminder at end with properties {name: item 1 of argv, body: item 2 of argv}
		end tell
	end tell
end run

